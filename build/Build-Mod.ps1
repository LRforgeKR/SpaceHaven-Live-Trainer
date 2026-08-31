param(
    [Parameter(Mandatory=$true)]
    [string]$SpaceHavenJar,

    [string]$OutputJar = (Join-Path $PSScriptRoot "..\mod\SpaceHavenLiveTrainer\SpaceHavenLiveTrainer.jar")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SpaceHavenJar)) {
    throw "spacehaven.jar non trovato: $SpaceHavenJar"
}

$javac = Get-Command javac -ErrorAction Stop
$jar = Get-Command jar -ErrorAction Stop

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = Join-Path $root "src\mod\com\luca\spacehaven\livetrainer\LiveTrainerAspect.java"
$aop = Join-Path $root "src\mod\META-INF\aop.xml"
$temp = Join-Path $env:TEMP ("spacehaven-live-trainer-build-" + [guid]::NewGuid().ToString("N"))

$stubSrc = Join-Path $temp "stubsrc\org\aspectj\lang\annotation"
$stubClasses = Join-Path $temp "stubclasses"
$classes = Join-Path $temp "classes"

New-Item -ItemType Directory -Force -Path $stubSrc, $stubClasses, (Join-Path $classes "META-INF") | Out-Null

@'
package org.aspectj.lang.annotation;
import java.lang.annotation.*;
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Aspect { String value() default ""; }
'@ | Set-Content -Encoding ASCII (Join-Path $stubSrc "Aspect.java")

@'
package org.aspectj.lang.annotation;
import java.lang.annotation.*;
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface After {
    String value();
    String argNames() default "";
}
'@ | Set-Content -Encoding ASCII (Join-Path $stubSrc "After.java")

& $javac.Source --release 8 -d $stubClasses (Join-Path $stubSrc "Aspect.java") (Join-Path $stubSrc "After.java")
if ($LASTEXITCODE -ne 0) { throw "Errore compilazione stub AspectJ." }

$cp = "$SpaceHavenJar;$stubClasses"
& $javac.Source --release 8 -cp $cp -d $classes $source
if ($LASTEXITCODE -ne 0) { throw "Errore compilazione mod." }

Copy-Item $aop (Join-Path $classes "META-INF\aop.xml") -Force

$outputDir = Split-Path $OutputJar -Parent
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
if (Test-Path $OutputJar) { Remove-Item $OutputJar -Force }

Push-Location $classes
try {
    & $jar.Source --create --file $OutputJar .
    if ($LASTEXITCODE -ne 0) { throw "Errore creazione JAR." }
} finally {
    Pop-Location
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Creato: $OutputJar"
