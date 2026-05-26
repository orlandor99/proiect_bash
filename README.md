# Ops-Assistant - Sistem de Automatizare, Audit și Servicii Linux

## 📋 Descriere

**Ops-Assistant** este un utilitar de administrare în linie de comandă (CLI) dezvoltat în Bash. Soluția automatizează monitorizarea resurselor, gestionarea backup-ului, auditul de securitate și verificarea stării serviciilor esențiale pe un server Linux.

### Probleme rezolvate:
- ✅ Monitorizarea continuă a resurselor de sistem (disc, memorie)
- ✅ Crearea și securizarea backup-urilor configurației
- ✅ Auditul securității și gestionarea utilizatorilor
- ✅ Verificarea stării serviciilor critice
- ✅ Logare automată și rotația jurnalelor

---

## 🚀 Ghid de instalare

### Cerințe preliminare:
- Sistem Linux cu Bash 
- Acces root sau permisiuni sudo pentru anumite operații
- Comenzi disponibile: `df`, `free`, `tar`, `systemctl`, `awk`, `sed`, `gzip`

### Pași de instalare:

1. **Clonați sau descărcați proiectul:**
   ```bash
   git clone <repository-url>
   cd proiect
   ```

2. **Creați structura de directoare:**
   ```bash
   mkdir -p src config backups reports log_archive
   ```

3. **Copiați scriptul principal:**
   ```bash
   cp manager.sh src/
   chmod +x src/manager.sh
   ```

4. **Configurați fișierul de setări:**
   ```bash
   cp settings.conf config/
   # Editați config/settings.conf după nevoie
   ```

5. **Testați instalarea:**
   ```bash
   cd src
   ./manager.sh --health
   ```

---

## ⚙️ Configurare

### Fișierul `config/settings.conf`

Toate parametrii scriptului sunt definiti în fișierul extern de configurare. Aceasta permite modificarea comportamentului fără a altera codul sursă.

#### Parametri disponibili:

```bash
# Directoare
REPORTS_DIR="../reports"           # Locație rapoarte de diagnostic
BACKUP_DIR="../backups"            # Locație arhive backup
CONFIG_DIR="../config"             # Locație fișiere configurare
LOG_ARCHIVE_DIR="../log_archive"   # Locație jurnale arhivate

# Praguri de monitorizare
DISK_THRESHOLD=80                  # Procent utilizare disc (alertă dacă depășit)
MEMORY_THRESHOLD=80                # Procent utilizare memorie

# Permisiuni backup
BACKUP_PERMISSIONS="600"           # Permisiuni fișier backup (rwx------)

# Servicii monitorizate
SERVICES=("sshd" "cron" "nginx")   # Lista servicii de verificat

# Logging
LOG_FILE="../log_archive/activity.log"   # Fișier jurnal activități
LOG_MAX_SIZE_MB=10                 # Dimensiune maximă jurnal (MB)

# Format timestamp
TIMESTAMP_FORMAT="+%Y-%m-%d_%H-%M-%S"   # Format dată/oră în jurnale
```

### Cum se editează `settings.conf`:

```bash
# Deschideți fișierul cu editor
vi config/settings.conf

# Modificați valorile după nevoie:
DISK_THRESHOLD=90          # Ridică pragul la 90%
SERVICES=("sshd" "mysql")  # Schimbă serviciile monitorizate

# Salvați și ieșiți
```

---

## 📝 Exemple de comenzi (CLI)

### 1. Verificare resurse (Health Check)
```bash
./src/manager.sh --health
```
**Output:**
- Procentaj utilizare disc /
- Totalul, utilizat și liber din memoria RAM
- Genereaza raport in `reports/health_report_*.txt`
- Logheaza in `activity.log`

**Exemplu:**
```
[INFO] Utilizarea discului este la 45% 
Monitorizare memorie:
  Total : 15.50 GB
  Used  : 8.25 GB
  Free  : 7.25 GB
[INFO] Raport generat cu succes: ../reports/health_report_2026-05-26_16-33-41.txt
```

---

### 2. Backup asigurat (Backup)
```bash
./src/manager.sh --backup
```
**Output:**
- Comprimează folderul `config/` într-o arhivă `.tar.gz`
- Aplică permisiuni restrictive (600)
- Salveaza in `backups/`
- Logheaza in `activity.log`

**Exemplu:**
```
[INFO] Se pregătește backup-ul...
[SUCCESS] Arhiva config_backup_20260526.tar.gz a fost creată.
[INFO] Permisiuni setate la 600
```

---

### 3. Verificare servicii (Services)
```bash
./src/manager.sh --services
```
**Output:**
- Verifica starea fiecarui serviciu din lista SERVICES
- Afisează ACTIVE sau INACTIVE pentru fiecare
- Logheaza in `activity.log`

**Exemplu:**
```
[INFO] Verificare servicii critice...
Service: SSHD - Status: ACTIVE
Service: CRON - Status: ACTIVE
Service: NGINX - Status: INACTIVE (Atentie!)
```

---

### 4. Audit de securitate (Security)
```bash
./src/manager.sh --security
```
**Output:**
- Listează utilizatorii cu acces shell activ (/bin/bash)
- Afișează ultimele 5 sesiuni de logare
- Logheaza în `activity.log`

**Exemplu:**
```
[INFO] Se inițializează auditul de securitate...

Utilizatori identificați cu shell activ (/bin/bash):
- root
- student

Ultimele 5 sesiuni de accesare a sistemului (last):
student pts/0 192.168.1.5 Sat May 2 17:10 still logged in
...
```

---

### 5. Executa toate modulele (Complete Flow)
```bash
./src/manager.sh --all
```
**Output:**
- Executa toate modulele (--health, --backup, --security, --services)
- Afişează doar rezumatul final
- Logheaza rezultatele în `activity.log`

**Exemplu:**
```
=== FLUX COMPLET ===
Generat: marți 26 mai 2026, 16:33:41 +0300

1. Audit Health... OK
2. Backup Config... OK
3. Audit Security... OK
4. Service Check... OK
[SUCCESS] Flux finalizat.
```

---

## 📂 Structura folderelor

```
proiect/
│
├── README.md                      # Documentație proiect 
│
├── src/                          # Cod sursă
│   └── manager.sh                # Script principal executabil
│
├── config/                       # Configurare
│   └── settings.conf             # Variabile globale și praguri
│
├── backups/                      # Fișiere de siguranță arhivate
│
└── reports/                      # Rapoarte de diagnostic

```

### Descrierea folderelor:

| Folder | Descriere |
|--------|-----------|
| **src/** | Conține scriptul principal executabil (manager.sh) |
| **config/** | Găzduiește fișierul settings.conf cu variabilele globale |
| **backups/** | Locul unde vor fi arhivate fișierele de siguranță |
| **reports/** | Locul unde vor fi salvate rapoartele de diagnostic |

---

## 📝 Jurnalele și arhivele

Jurnalele de activitate sunt salvate direct în folderul proiect:
- `activity.log` - Jurnal curent cu toate operațiunile
- Jurnalele arhivate sunt rotite automat când depășesc 10MB

---

## 🔧 Caracteristici avansate

### Rotația automată a jurnalelor
- Jurnalele sunt rotite automat când depășesc 10MB
- Jurnalele vechi sunt arhivate și comprimate cu gzip
- Format: `activity-YYYY-MM-DD_HH-MM-SS.log.gz`

### Idempotență
- Scriptul poate fi rulat de mai multe ori fără efecte nedorite
- Creează automat directoarele necesare dacă nu există
- Nu suprascrie rapoarte existente (folosește timestamp)

### Securitate
- Backup-urile sunt protejate cu permisiuni `600` (rw------)
- Auditează și loghează accesul utilizatorilor
- Verifica integritatea serviciilor critice

---

## 📞 Depanare și probleme frecvente

### Eroare: "Fișierul de configurare lipseste"
```bash
# Asigurați-vă că settings.conf este în ../config/
# Rulați scriptul din directorul src/
cd src
./manager.sh --health
```

### Eroare: "Permisiune refuzată"
```bash
# Asigurați-vă că scriptul are permisiuni de execuție
chmod +x manager.sh

# Unele comenzi necesită acces root
sudo ./manager.sh --health
```

### Jurnalul crește prea repede
```bash
# Măriți pragul de rotație în settings.conf
LOG_MAX_SIZE_MB=50    # Crește la 50MB în loc de 10MB
```

