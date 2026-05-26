#!/bin/bash

CONFIG_FILE="../config/settings.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Fișierul de configurare lipseste: $CONFIG_FILE"
    exit 1
fi

# Variabile globale
source ../config/settings.conf

mkdir -p "$BACKUP_DIR" "$REPORTS_DIR" "$CONFIG_DIR" "$LOG_ARCHIVE_DIR"

rotate_logs() {
    local MAX_SIZE_BYTES=$((LOG_MAX_SIZE_MB * 1024 * 1024))

    if [ -f "$LOG_FILE" ]; then
        local CURRENT_SIZE
        CURRENT_SIZE=$(stat -c%s "$LOG_FILE")

        if [ "$CURRENT_SIZE" -ge "$MAX_SIZE_BYTES" ]; then
            local TIMESTAMP
            TIMESTAMP=$(date "$TIMESTAMP_FORMAT")

            local LOG_BASENAME
            LOG_BASENAME=$(basename "$LOG_FILE")

            local ARCHIVED_LOG
            ARCHIVED_LOG="$LOG_ARCHIVE_DIR/${LOG_BASENAME%.log}-$TIMESTAMP.log"

            mv "$LOG_FILE" "$ARCHIVED_LOG"
            gzip "$ARCHIVED_LOG"
            touch "$LOG_FILE"

            echo "[INFO] Log rotit: $(basename "$ARCHIVED_LOG").gz"
        fi
    fi
}

case "$1" in
--health)
	rotate_logs
	echo -e "[INFO] Se initializeaza auditul de sistem..."
	TIMESTAMP=$(date "$TIMESTAMP_FORMAT")
	REPORT_FILE="$REPORTS_DIR/health_report_$TIMESTAMP.txt"
	# Extrage procentul de utilizare pentru /
	DISK_USAGE=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
	# Verificare prag
	if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
		DISK_STATUS="[WARNING]"
		DISK_LINE="${DISK_STATUS} Utilizarea discului a depasit pragul(Threshold) (${DISK_USAGE}% utilizat)"
	else
    		DISK_STATUS="[INFO]"
		DISK_LINE="${DISK_STATUS} Utilizarea discului este la ${DISK_USAGE}% "
	fi

	# Colectare date memorie (în MB)
	MEM_TOTAL=$(free -b | awk '/^Mem:/ {printf "%.2f", $2/1024/1024/1024}' | sed 's/\./,/g')
	MEM_USED=$(free -b | awk '/^Mem:/ {printf "%.2f", $3/1024/1024/1024}' | sed 's/\./,/g')
	MEM_FREE=$(free -b | awk '/^Mem:/ {printf "%.2f", $4/1024/1024/1024}' | sed 's/\./,/g')
		
	# Scriere raport
	{
    	echo "======================================"
    	echo " Raport de diagnostic si monitorizare"
    	echo " Generat: $(date)"
    	echo "======================================"
    	echo
    	echo "$DISK_LINE"
    	echo
    	echo "Monitorizare memorie:"
    	echo "  Total : ${MEM_TOTAL} GB"
    	echo "  Used  : ${MEM_USED} GB"
    	echo "  Free  : ${MEM_FREE} GB"
    	echo
	} >> "$REPORT_FILE"
	# ==============================
	# Terminal output
	# ==============================
	echo -e "$DISK_LINE"
	echo -e "Monitorizare memorie:"
	echo -e "  Total : ${MEM_TOTAL} GB"
	echo -e "  Used  : ${MEM_USED} GB"
	echo -e "  Free  : ${MEM_FREE} GB"
	echo -e "[INFO] Raport generat cu succes: $REPORT_FILE"
	
	# ==============================
	# Log file output
	# ==============================
	{
		echo ""
		echo "=====================================" 
		echo "=== HEALTH CHECK ==="
		echo "Generat: $(date)"
		echo "====================================="
		echo ""
		echo "$DISK_LINE"
		echo ""
		echo "Monitorizare memorie:"
		echo "  Total : ${MEM_TOTAL} GB"
		echo "  Used  : ${MEM_USED} GB"
		echo "  Free  : ${MEM_FREE} GB"
	} >> "$LOG_FILE"
	exit 0
;;
--backup)
	rotate_logs
	echo "[INFO] Se pregătește backup-ul..."
	
	if [ ! -d "$CONFIG_DIR" ]; then
        echo "[ERROR] Directorul $CONFIG_DIR nu există!"
		echo "[ERROR] Directorul $CONFIG_DIR nu există! ($(date))" >> "$LOG_FILE"
        exit 1
    fi

    BACKUP_NAME="config_backup_$(date +%Y%m%d).tar.gz"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

    # Criere arhivă
    tar -czf "$BACKUP_PATH" "$CONFIG_DIR"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Eroare la crearea arhivei!"
		echo "[ERROR] Eroare la crearea arhivei! ($(date))" >> "$LOG_FILE"
        exit 1
    fi

    echo "[SUCCESS] Arhiva $BACKUP_NAME a fost creată."

    # Setare permisiuni securizate
    chmod "$BACKUP_PERMISSIONS" "$BACKUP_PATH"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Nu s-au putut seta permisiunile!"
		echo "[ERROR] Nu s-au putut seta permisiunile! ($(date))" >> "$LOG_FILE"
        exit 1
    fi

    echo "[INFO] Permisiuni setate la $BACKUP_PERMISSIONS"
	
	# ==============================
	# Log file output
	# ==============================
	{
		echo ""
		echo "====================================="
		echo "=== BACKUP OPERATION ==="
		echo "Generat: $(date)"
		echo "====================================="
		echo ""
		echo "[SUCCESS] Backup creat: $BACKUP_NAME"
		echo "[INFO] Permisiuni: $BACKUP_PERMISSIONS"
	} >> "$LOG_FILE"
    exit 0
;;
--services)
	rotate_logs
	echo "[INFO] Verificare servicii critice..."
	echo ""

    	for SERVICE in "${SERVICES[@]}"; do
        	STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null)
        	if [ "$STATUS" = "active" ]; then
            		echo "Service: ${SERVICE^^} - Status: ACTIVE"
        	else
            		echo "Service: ${SERVICE^^} - Status: INACTIVE (Atentie!)"
        	fi
    	done
	
	# ==============================
	# Log file output
	# ==============================
	{
		echo ""
		echo "====================================="
		echo "=== SERVICE STATUS CHECK ==="
		echo "Generat: $(date)"
		echo "====================================="
		echo ""
		for SERVICE in "${SERVICES[@]}"; do
			STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null)
			if [ "$STATUS" = "active" ]; then
				echo "Service: ${SERVICE^^} - Status: ACTIVE"
			else
				echo "Service: ${SERVICE^^} - Status: INACTIVE"
			fi
		done
	} >> "$LOG_FILE"
	exit 0
;;
--security)
	rotate_logs
    echo "[INFO] Se inițializează auditul de securitate..."

    # =========================
    # Utilizatori cu shell valid
    # =========================
    echo ""
    echo "Utilizatori identificați cu shell activ (/bin/bash):"

    awk -F: '$7 ~ /(bash|sh|zsh)$/ {print "- " $1}' /etc/passwd

    # =========================
    # Ultimele logări
    # =========================
    echo ""
    echo "Ultimele 5 sesiuni de accesare a sistemului (last):"

    last -n 5 | head -n 5

    {
        echo "=== AUDIT DE SECURITATE ==="
        echo "Generat: $(date)"
        echo ""
        echo "Useri cu shell acces:"
        awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1}' /etc/passwd
        echo ""
        echo "Ultimele 5 logari:"
        last -n 5 | head -n 5
    } >> "$LOG_FILE"

    echo ""
    echo "[SUCCESS] Datele de securitate au fost salvate în $LOG_FILE"	
    exit 0
;;
--all)
rotate_logs

    bash "$0" --health >/dev/null 2>&1
    HEALTH_RESULT=$?

    bash "$0" --backup >/dev/null 2>&1
    BACKUP_RESULT=$?

    bash "$0" --security >/dev/null 2>&1
    SECURITY_RESULT=$?

    bash "$0" --services >/dev/null 2>&1
    SERVICES_RESULT=$?

    # ==============================
    # Terminal output
    # ==============================
    echo "=== FLUX COMPLET ==="
    echo "Generat: $(date)"
    echo ""
    if [ $HEALTH_RESULT -eq 0 ]; then
        echo "1. Audit Health... OK"
    else
        echo "1. Audit Health... FAILED"
    fi
    if [ $BACKUP_RESULT -eq 0 ]; then
        echo "2. Backup Config... OK"
    else
        echo "2. Backup Config... FAILED"
    fi
    if [ $SECURITY_RESULT -eq 0 ]; then
        echo "3. Audit Security... OK"
    else
        echo "3. Audit Security... FAILED"
    fi
    if [ $SERVICES_RESULT -eq 0 ]; then
        echo "4. Service Check... OK"
    else
        echo "4. Service Check... FAILED"
    fi
    echo "[SUCCESS] Flux finalizat."
    
    # ==============================
    # Log file output
    # ==============================
    {
        echo ""
        echo "====================================="
        echo "=== FLUX COMPLET ==="
        echo "Generat: $(date)"
        echo "====================================="
        echo ""
        if [ $HEALTH_RESULT -eq 0 ]; then
            echo "1. Audit Health... OK"
        else
            echo "1. Audit Health... FAILED"
        fi
        if [ $BACKUP_RESULT -eq 0 ]; then
            echo "2. Backup Config... OK"
        else
            echo "2. Backup Config... FAILED"
        fi
        if [ $SECURITY_RESULT -eq 0 ]; then
            echo "3. Audit Security... OK"
        else
            echo "3. Audit Security... FAILED"
        fi
        if [ $SERVICES_RESULT -eq 0 ]; then
            echo "4. Service Check... OK"
        else
            echo "4. Service Check... FAILED"
        fi
        echo "[SUCCESS] Flux finalizat."
    } >> $LOG_FILE
    exit 0
;;
*)
    echo "[ERROR] Opțiune necunoscută: $1"
    echo "Utilizare: ./manager.sh [--health|--backup|--services|--security|--all]"
    exit 1
;;
esac
