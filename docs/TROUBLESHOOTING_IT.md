# Troubleshooting

## GUI: MOD NON CONNESSO

Con Space Haven avviato dal Mod Loader e una partita caricata:

```bat
netstat -ano | findstr :17840
```

Se compare `127.0.0.1:17840 ... LISTENING`, il server del mod e attivo.

## Il mod non compare nel Mod Loader

- controlla che la cartella sia `SpaceHaven\mods\SpaceHavenLiveTrainer`;
- verifica che dentro ci siano `info.xml` e `SpaceHavenLiveTrainer.jar`;
- esegui `Clear QuickLaunch cache`;
- riavvia il Mod Loader.

## L'installer non trova il gioco

Seleziona manualmente la cartella di Space Haven. Deve contenere `spacehaven.jar`.

## Accesso negato durante l'installazione

Esegui `INSTALLA_MOD.bat` come amministratore. La GUI invece non richiede elevazione.
