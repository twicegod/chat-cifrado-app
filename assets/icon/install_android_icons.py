"""
Toma icon.png (1024x1024) y genera las variantes para Android en sus
carpetas mipmap-*, reemplazando los iconos default de Flutter.

Tambien crea el ic_launcher_round.png (algunos lanzadores lo usan).

Densidades segun Android:
    mdpi    -> 48x48
    hdpi    -> 72x72
    xhdpi   -> 96x96
    xxhdpi  -> 144x144
    xxxhdpi -> 192x192
"""
from PIL import Image
from pathlib import Path

DENSIDADES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Carpetas relativas al script (que esta en assets/icon/)
ROOT = Path(__file__).resolve().parents[2]
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

src = Image.open(Path(__file__).parent / "icon.png")
print(f"Fuente: {src.size}")

for densidad, tamanio in DENSIDADES.items():
    carpeta = ANDROID_RES / f"mipmap-{densidad}"
    carpeta.mkdir(parents=True, exist_ok=True)

    # Icono cuadrado normal
    img = src.resize((tamanio, tamanio), Image.LANCZOS)
    img.save(carpeta / "ic_launcher.png", "PNG", optimize=True)

    # Icono redondo (algunos launchers lo usan)
    img.save(carpeta / "ic_launcher_round.png", "PNG", optimize=True)

    print(f"OK {carpeta.relative_to(ROOT)}/ic_launcher.png  ({tamanio}x{tamanio})")

print("\nListo. Los iconos default de Flutter fueron reemplazados.")
