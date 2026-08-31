# Architettura e logica

Il progetto e diviso in due parti.

La GUI e il pannello di controllo esterno. Non modifica direttamente la memoria del gioco e non apre continuamente il salvataggio.

Il mod viene caricato insieme a Space Haven e puo accedere agli oggetti della partita attiva.

La comunicazione usa esclusivamente `127.0.0.1:17840`.

## Flusso di un comando

```text
utente -> GUI -> comando localhost -> coda del mod -> update del gioco -> modifica
```

Il comando ricevuto non viene applicato direttamente dal thread di rete. Viene messo in coda e poi eseguito durante il normale ciclo di aggiornamento del gioco.

## Toggle continui

Funzioni come Infinite Resources, Salute infinita e Ossigeno infinito non sono azioni singole.

Quando sono ON il mod controlla periodicamente i relativi valori e interviene solo quando necessario.

Infinite Resources, per esempio, lascia che Space Haven consumi normalmente i materiali e poi reintegra la differenza. Questo evita di bloccare la logistica originale.

## Ricerca

Quando possibile il trainer richiama la logica interna di sblocco della ricerca invece di cambiare semplicemente un flag. In questo modo il gioco puo eseguire anche gli sblocchi associati alla tecnologia.
