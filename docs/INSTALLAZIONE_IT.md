# Installazione - Italiano

## Metodo consigliato

Scarica `SpaceHaven-Live-Trainer-v0.7.2.zip` dalla pagina Releases, estrailo e avvia:

```text
INSTALLA_MOD.bat
```

L'installer cerca Space Haven nelle librerie Steam conosciute. Se non lo trova, apre una finestra per selezionare manualmente la cartella del gioco.

La cartella corretta contiene:

```text
spacehaven.jar
```

L'installer verifica inoltre che esista:

```text
SpaceHaven\mods
```

Se `mods` non esiste, installa prima Space Haven Mod Loader.

## Aggiornamento

Se esiste gia una cartella:

```text
mods\SpaceHavenLiveTrainer
```

l'installer la sposta automaticamente in un backup con data e ora, poi installa la nuova versione.

## Dopo l'installazione

1. Apri Mod Loader.
2. Controlla che il trainer risulti v0.7.2.
3. Esegui `Clear QuickLaunch cache`.
4. Avvia Space Haven dal Mod Loader.
5. Carica una partita.
6. Avvia `AVVIA_GUI.bat`.

## Permessi amministratore

La GUI non richiede privilegi amministratore.

L'installer normalmente non ne ha bisogno. Se Windows impedisce la scrittura nella cartella Steam sotto `Program Files`, esegui **solo `INSTALLA_MOD.bat`** come amministratore.
