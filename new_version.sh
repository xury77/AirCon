#!/bin/bash
set -e

echo "Pobieranie najnowszych zmian z repozytorium"
git pull

# Pobieranie ostatniego tagu
OLD_VERSION=$(git tag | tail -n 1)
echo "Stara wersja: $OLD_VERSION"

# Ustawienie nowej wersji
NEW_VERSION=$1
if [ -z "$NEW_VERSION" ]; then
  echo "Nowa wersja nie została podana"
  exit 1
fi
echo "Nowa wersja: $NEW_VERSION"

# Ustawienie wiadomości tagu
if [ -z "$2" ]; then
  NEW_VERSION_MSG="v$1"
else
  NEW_VERSION_MSG=$2
fi
echo "Wiadomość nowej wersji: $NEW_VERSION_MSG"

# Tworzenie nowego tagu
git tag -a "$NEW_VERSION" -m "$NEW_VERSION_MSG"

# Zamiana wersji w plikach
for f in ./aircon/__init__.py ./hassio/config.json ./docker-compose.yaml; do
  if [[ -f "$f" ]]; then
    echo "Zamiana wersji w pliku: $f"
    echo "Używając sed z: OLD_VERSION=$OLD_VERSION i NEW_VERSION=$NEW_VERSION"
    
    # Użycie sed z opcją -i dla Linux
    sed -i -e "s/$OLD_VERSION/$NEW_VERSION/g" "$f"
  else
    echo "Plik $f nie istnieje."
  fi
done

# Commit zmian i aktualizacja tagu
git commit -a -m "$NEW_VERSION"
git tag -d "$NEW_VERSION"
git tag -a "$NEW_VERSION" -m "$NEW_VERSION_MSG"
docker buildx rm --all-inactive --force
docker buildx create --name multiarch --driver docker-container --use || true
docker buildx build --platform linux/arm/v7,linux/arm64,linux/amd64,linux/386 -t xury77/aircon:$NEW_VERSION --push .
git push
git push --tags
