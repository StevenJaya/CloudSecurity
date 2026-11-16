#!/bin/bash
# setup-semester.sh
# Mata Kuliah Cloud Security - S1 Informatika
#
# Skrip ini menarik (pull) seluruh image Docker yang dipakai sepanjang
# semester. Karena keterbatasan bandwidth internet di kelas, skrip ini
# dibagi 2 bagian:
#
#   BAGIAN 1 (dikerjakan di kelas, Pertemuan 1)
#     Menarik 1 image saja (MinIO) sebagai uji coba, untuk memastikan
#     Docker dan koneksi jaringan masing-masing laptop berfungsi normal.
#
#   BAGIAN 2 (dikerjakan mandiri di rumah, sebelum Pertemuan 2)
#     Menarik sisa image untuk kebutuhan Pertemuan 3 sampai 13.
#     Dikerjakan sendiri-sendiri, tidak perlu menunggu jam kelas.
#
# Cara pakai:
#   bash setup-semester.sh kelas    -> jalankan Bagian 1 saja
#   bash setup-semester.sh rumah    -> jalankan Bagian 2 saja
#   bash setup-semester.sh semua    -> jalankan Bagian 1 dan 2 sekaligus
#
# Catatan versi image:
#   kindest/node TIDAK punya tag "latest" di Docker Hub, jadi wajib
#   ditulis versi spesifik (kalau tidak, perintah pull akan gagal).
#   Versi di skrip ini sudah dicek tersedia per Agustus 2026. Kalau
#   suatu saat gagal pull karena versi sudah ditarik dari registry,
#   cek tag terbaru di hub.docker.com lalu perbarui baris terkait di
#   Bagian 2.
#
#   Wazuh (dipakai Pertemuan 12) sengaja TIDAK ditarik lewat "docker
#   pull" manual seperti image lain, karena deployment resminya butuh
#   docker-compose khusus dari repo wazuh-docker (termasuk konfigurasi
#   sertifikat antar-container yang tidak bisa dilakukan cuma dengan
#   pull image satu per satu). Skrip ini otomatis meng-clone repo
#   tersebut ke ~/wazuh-docker dan menarik image lewat "docker compose
#   pull" supaya versinya pasti cocok dengan file compose resminya.

set -e

MODE="${1:-kelas}"

pull_image() {
  local nama="$1"
  local image="$2"
  echo ""
  echo ">> Menarik image untuk: $nama"
  echo "   ($image)"
  docker pull "$image"
}

jalankan_bagian_1() {
  echo "================================================================"
  echo " BAGIAN 1: UJI COBA DI KELAS (Pertemuan 1)"
  echo "================================================================"
  echo "Menarik 1 image untuk memastikan Docker dan jaringan berfungsi."
  echo "Dipakai lagi di Pertemuan 2 dan 6."
  pull_image "MinIO (object storage)" "minio/minio"

  echo ""
  echo "Verifikasi:"
  docker images | grep -i minio || true
  echo ""
  echo "Jika baris minio/minio muncul di atas, berarti Docker dan"
  echo "koneksi internet laptop kamu sudah siap dipakai untuk semester ini."
  echo ""
  echo "Image lainnya TIDAK perlu ditarik hari ini. Kerjakan Bagian 2"
  echo "di rumah, tidak harus langsung setelah kelas selesai, cukup"
  echo "sebelum Pertemuan 3 (Keycloak dipakai mulai Pertemuan 3)."
}

jalankan_bagian_2() {
  echo "================================================================"
  echo " BAGIAN 2: DIKERJAKAN MANDIRI DI RUMAH"
  echo "================================================================"
  echo "Setiap mahasiswa menjalankan bagian ini sendiri-sendiri di luar"
  echo "jam kelas. Total unduhan sekitar 3-5 GB, sediakan waktu dan"
  echo "koneksi yang stabil (disarankan tidak memakai kuota seluler)."

  pull_image "Keycloak (identity provider, dipakai Pertemuan 3-4)" "quay.io/keycloak/keycloak:latest"
  pull_image "HashiCorp Vault (dipakai Pertemuan 6)" "hashicorp/vault"
  pull_image "Trivy (dipakai Pertemuan 7, 10, 11)" "aquasec/trivy"
  pull_image "kind node image (cluster Kubernetes, dipakai Pertemuan 9)" "kindest/node:v1.33.12"
  pull_image "kube-bench (dipakai Pertemuan 9)" "aquasec/kube-bench"
  pull_image "Prowler (dipakai Pertemuan 13)" "toniblyx/prowler"

  echo ""
  echo ">> Menyiapkan Wazuh (dipakai Pertemuan 12)"
  echo "   Wazuh tidak bisa disiapkan lewat 'docker pull' biasa, deployment"
  echo "   resminya butuh repo docker-compose khusus dari Wazuh sendiri"
  echo "   (lengkap dengan konfigurasi sertifikat antar-container)."
  if [ -d "$HOME/wazuh-docker" ]; then
    echo "   Folder wazuh-docker sudah ada, lewati clone ulang."
  else
    git clone https://github.com/wazuh/wazuh-docker.git -b stable --single-branch "$HOME/wazuh-docker"
  fi
  cd "$HOME/wazuh-docker/single-node"
  echo "   Menarik image Wazuh sesuai versi resmi di repo ini (bisa"
  echo "   memakan waktu, image indexer+manager+dashboard cukup besar):"
  docker compose pull
  cd - > /dev/null

  echo ""
  echo "Verifikasi seluruh image:"
  docker images
  echo ""
  echo "Kalau semua baris di atas muncul, Bagian 2 selesai. Simpan"
  echo "screenshot hasil 'docker images' ini sebagai bukti setup."
}

case "$MODE" in
  kelas)
    jalankan_bagian_1
    ;;
  rumah)
    jalankan_bagian_2
    ;;
  semua)
    jalankan_bagian_1
    jalankan_bagian_2
    ;;
  *)
    echo "Pemakaian: bash setup-semester.sh [kelas|rumah|semua]"
    exit 1
    ;;
esac

echo ""
echo "Selesai."
