#!/bin/sh
docker-compose down -v
rm -rf client server

echo "Create dirs.."
mkdir -p client/share server/shares

echo "Create some random file to test sync"
echo "Test file client" > client/share/client_test.txt

touch client/.gitkeep client/share/.gitkeep
touch server/.gitkeep server/shares/.gitkeep

sleep 1