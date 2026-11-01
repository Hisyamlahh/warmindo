#!/usr/bin/env bash
# ==============================================================================
# Script: pre-commit.sh
# Git Pre-commit Hook untuk validasi kode Flutter & integritas berkas Maestro
# Untuk mengaktifkan: cp tools/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# ==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> [Pre-commit] Menjalankan pemeriksaan kualitas kode...${NC}"

# 1. Analisis Statis Flutter
echo -e "${YELLOW}1. Menjalankan flutter analyze...${NC}"
flutter analyze
echo -e "${GREEN}[PASS] flutter analyze selesai tanpa error.${NC}"

# 2. Pengujian Unit & Widget Test
echo -e "${YELLOW}2. Menjalankan flutter test...${NC}"
flutter test
echo -e "${GREEN}[PASS] Seluruh flutter test lulus 100%.${NC}"

# 3. Verifikasi Keberadaan Berkas Alur Maestro
echo -e "${YELLOW}3. Memvalidasi berkas konfigurasi Maestro E2E...${NC}"
REQUIRED_FLOWS=(
    "maestro/flows/landing.yaml"
    "maestro/flows/login.yaml"
    "maestro/flows/scrolling.yaml"
    ".github/workflows/maestro.yaml"
)

for file in "${REQUIRED_FLOWS[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}[FAIL] Berkas wajib $file tidak ditemukan!${NC}"
        exit 1
    fi
    if [ ! -s "$file" ]; then
        echo -e "${RED}[FAIL] Berkas $file kosong!${NC}"
        exit 1
    fi
done
echo -e "${GREEN}[PASS] Seluruh berkas Maestro valid dan lengkap.${NC}"

echo -e "${GREEN}>>> [Pre-commit] Validasi sukses! Commit diizinkan.${NC}"
exit 0
