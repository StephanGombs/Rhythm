# Guide de déploiement VPS

Comment déplacer le backend du jeu Rythme de votre machine locale vers un VPS afin que les joueurs puissent s'y connecter.

---

## Ce qui change entre le développement local et le VPS

| Élément | Dev local | VPS |
|---|---|---|
| URL du backend dans Godot | `http://127.0.0.1:8000` | `http://<VOTRE_IP_VPS>:8000` |
| Hôte de la base de données dans `.env` | `localhost:5433` | `postgres:5432` (interne Docker) |
| `DEBUG` dans `.env` | `True` | `False` |
| `SECRET_KEY` dans `.env` | valeur temporaire | clé aléatoire forte |
| Build Godot | debug (éditeur) | build release exporté |

---

## 1. Préparer le VPS

Il vous faut un VPS Linux (Ubuntu 22.04 recommandé). Exécutez ces commandes une seule fois après avoir obtenu l'accès SSH :

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Installer le plugin Docker Compose (si non inclus)
sudo apt install -y docker-compose-plugin

# Vérifier
docker --version
docker compose version
```

---

## 2. Ouvrir le pare-feu

Le port 8000 doit être accessible depuis Internet pour que les clients Godot puissent se connecter.

```bash
sudo ufw allow 22      # SSH — ne pas supprimer pour éviter de se bloquer
sudo ufw allow 8000    # API backend
sudo ufw enable
```

> Le port 5432 (PostgreSQL) **n'a pas** besoin d'être ouvert — il reste interne à Docker.

---

## 3. Uploader le projet

Depuis votre machine locale, copiez le projet sur le VPS :

```bash
# Remplacez user@VOTRE_IP_VPS et le chemin selon vos besoins
scp -r "c:/Users/steph/OneDrive/Desktop/My personnal projects/Rhythm" user@VOTRE_IP_VPS:~/rhythm
```

Ou utilisez Git si le projet est dans un dépôt :

```bash
git clone <url-de-votre-depot> ~/rhythm
```

---

## 4. Configurer l'environnement

Connectez-vous en SSH au VPS, puis modifiez `backend/.env` :

```bash
cd ~/rhythm
nano backend/.env
```

Contenu à définir :

```env
DATABASE_URL=postgresql+asyncpg://prod_user:CHANGEZ_CE_MOT_DE_PASSE@postgres:5432/rhythm_prod
SECRET_KEY=GÉNÉREZ_AVEC_LA_COMMANDE_CI-DESSOUS
DEBUG=False
SHIELD_PRICE=100
PERFECT_HIT_FUNDS=15
GOOD_HIT_FUNDS=10
BAD_HIT_FUNDS=5
```

Générer une clé SECRET_KEY forte :

```bash
openssl rand -hex 32
```

Copiez la sortie et collez-la comme valeur de `SECRET_KEY`.

---

## 5. Mettre à jour docker-compose.yml pour la production

Le fichier `docker-compose.yml` à la racine du projet utilise des identifiants de développement. Mettez à jour le service `postgres` pour correspondre aux identifiants de votre `.env` :

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: rhythm_postgres
    environment:
      POSTGRES_USER: prod_user
      POSTGRES_PASSWORD: CHANGEZ_CE_MOT_DE_PASSE
      POSTGRES_DB: rhythm_prod
    volumes:
      - rhythm_pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U prod_user -d rhythm_prod"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - app-network

  backend:
    build: ./backend
    env_file:
      - ./backend/.env
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - app-network

volumes:
  rhythm_pg_data:

networks:
  app-network:
    driver: bridge
```

> Le service `nginx` n'est pas nécessaire pour un test VPS de base — supprimez-le ou laissez-le commenté.

---

## 6. Démarrer le backend

```bash
cd ~/rhythm
docker compose up -d --build
```

Vérifiez que tout a bien démarré :

```bash
docker compose logs -f backend
```

Vous devriez voir :
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Testez depuis votre machine locale :

```bash
curl http://VOTRE_IP_VPS:8000/health
# Attendu : {"status":"ok"}
```

---

## 7. Mettre à jour le client Godot

Dans `rhythm/scripts/network/api_client.gd`, remplacez `YOUR_VPS_IP` par l'adresse IP réelle :

```gdscript
const BASE_URL_DEV  = "http://127.0.0.1:8000"
const BASE_URL_PROD = "http://VOTRE_IP_VPS:8000"   # ← mettez la vraie IP ici
const BASE_URL = BASE_URL_DEV if OS.is_debug_build() else BASE_URL_PROD
```

Lorsque vous exportez le jeu dans Godot (**Projet → Exporter → Release**), il utilisera automatiquement `BASE_URL_PROD`. Depuis l'éditeur Godot, c'est toujours le backend local qui est utilisé.

---

## 8. Maintenir le backend actif après déconnexion

Par défaut, `docker compose up -d` maintient les conteneurs en cours d'exécution. Pour survivre également à un redémarrage du VPS, ajoutez une politique de redémarrage dans le fichier compose :

```yaml
  backend:
    restart: unless-stopped

  postgres:
    restart: unless-stopped
```

Puis relancez `docker compose up -d` pour appliquer.

---

## Référence des commandes rapides

```bash
# Démarrer
docker compose up -d --build

# Arrêter
docker compose down

# Voir les logs
docker compose logs -f backend

# Redémarrer uniquement le backend (après un changement de code)
docker compose up -d --build backend

# Vérifier les conteneurs en cours d'exécution
docker compose ps
```

---

## Dépannage

**Godot ne reçoit pas de réponse / délai d'attente**
- Vérifiez `sudo ufw status` — le port 8000 doit afficher ALLOW
- Exécutez `curl http://VOTRE_IP_VPS:8000/health` depuis une autre machine pour confirmer que l'API est active
- Vérifiez `docker compose logs backend` pour les erreurs

**Connexion à la base de données refusée**
- Assurez-vous que `DATABASE_URL` dans `.env` utilise `postgres` (le nom du service Docker) comme hôte, et non `localhost`
- Vérifiez `docker compose ps` — le conteneur `postgres` doit être en bonne santé avant le démarrage du backend

**Les migrations ont échoué au démarrage**
- Lancez manuellement : `docker compose exec backend alembic upgrade head`
- Consultez les logs : `docker compose logs backend`

**Mauvais mot de passe / erreurs d'authentification après déploiement**
- Les mots de passe hachés localement ne fonctionneront pas avec une base de données de production vierge — les utilisateurs devront se réinscrire
