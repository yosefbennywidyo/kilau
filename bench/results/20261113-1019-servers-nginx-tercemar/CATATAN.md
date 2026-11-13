# Sesi ini tercemar; jangan dipakai untuk kesimpulan

Semua sel terukur 2-3x lebih lambat daripada smoke run beberapa menit sebelumnya
pada daya yang sama (`kilau-spinel-direct` S1 c16: 10.471 req/s di sini, 35.679 di
smoke run, 15.546 di sesi ulang `20261113-1242-servers-nginx` yang berjalan di
baterai). Ketiga repetisi tiap sel konsisten, jadi penyebabnya beban luar yang
menetap selama sesi (Chrome dan `coreaudiod` aktif saat diperiksa), bukan lonjakan.
Laptop juga pindah dari AC ke baterai pada 11:10:56, di tengah sesi.

Disimpan sebagai jejak. Sesi penggantinya: `bench/results/20261113-1242-servers-nginx`.
