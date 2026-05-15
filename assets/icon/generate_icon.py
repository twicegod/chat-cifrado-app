"""
Genera el icono de la app Chat Cifrado en varias resoluciones.

Diseño:
    - Fondo verde corporativo (#075E54)
    - Burbuja de chat blanca redondeada
    - Candado verde (#25D366) en el centro de la burbuja

Salidas:
    - icon.png            (1024x1024 — master para flutter_launcher_icons)
    - icon_foreground.png (1024x1024 — solo la burbuja+candado, fondo transparente,
                           para adaptive icon de Android 8+)
    - splash.png          (512x512 — para flutter_native_splash)
"""
from PIL import Image, ImageDraw

# Colores
VERDE_OSCURO = (7, 94, 84, 255)        # #075E54
VERDE_CLARO  = (37, 211, 102, 255)     # #25D366
BLANCO       = (255, 255, 255, 255)
TRANSPARENTE = (0, 0, 0, 0)


def dibujar_candado(draw: ImageDraw.ImageDraw, cx: int, cy: int, tamanio: int, color):
    """Dibuja un candado centrado en (cx, cy) con tamaño aproximado dado."""
    # Cuerpo del candado (cuadrado redondeado)
    ancho_cuerpo  = int(tamanio * 0.85)
    alto_cuerpo   = int(tamanio * 0.7)
    radio         = int(tamanio * 0.12)
    x0 = cx - ancho_cuerpo // 2
    y0 = cy - alto_cuerpo // 2 + int(tamanio * 0.1)
    x1 = x0 + ancho_cuerpo
    y1 = y0 + alto_cuerpo
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radio, fill=color)

    # Arco superior del candado
    ancho_arco = int(tamanio * 0.55)
    alto_arco  = int(tamanio * 0.55)
    arco_x0 = cx - ancho_arco // 2
    arco_y0 = y0 - alto_arco // 2
    arco_x1 = arco_x0 + ancho_arco
    arco_y1 = arco_y0 + alto_arco
    # Dibujo el arco con un ancho considerable
    grosor = int(tamanio * 0.1)
    draw.arc([arco_x0, arco_y0, arco_x1, arco_y1], start=180, end=360, fill=color, width=grosor)

    # Bolita central (cerradura)
    bolita_r = int(tamanio * 0.07)
    bolita_cy = y0 + int(alto_cuerpo * 0.4)
    draw.ellipse(
        [cx - bolita_r, bolita_cy - bolita_r, cx + bolita_r, bolita_cy + bolita_r],
        fill=VERDE_OSCURO if color == VERDE_CLARO else VERDE_CLARO,
    )


def crear_icon(size: int, con_fondo: bool = True) -> Image.Image:
    """Crea el icono completo en la resolucion dada."""
    img = Image.new("RGBA", (size, size), VERDE_OSCURO if con_fondo else TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Burbuja de chat blanca (redonda con un piquito en la esquina inferior izquierda)
    burbuja_padding = int(size * 0.15)
    bx0 = burbuja_padding
    by0 = burbuja_padding
    bx1 = size - burbuja_padding
    by1 = size - burbuja_padding
    radio_burbuja = int(size * 0.12)
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=radio_burbuja, fill=BLANCO)

    # Piquito de la burbuja (triangulito en la esquina inferior izquierda)
    piquito = int(size * 0.07)
    draw.polygon(
        [
            (bx0 + radio_burbuja, by1 - piquito),
            (bx0 - piquito // 2,  by1 + piquito),
            (bx0 + radio_burbuja * 2, by1 + piquito // 2),
        ],
        fill=BLANCO,
    )

    # Candado verde centrado en la burbuja
    cx = (bx0 + bx1) // 2
    cy = (by0 + by1) // 2
    dibujar_candado(draw, cx, cy, int(size * 0.45), VERDE_CLARO)

    return img


def crear_splash(size: int) -> Image.Image:
    """Crea el logo de splash (solo burbuja + candado, sin fondo)."""
    img = Image.new("RGBA", (size, size), TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    burbuja_padding = int(size * 0.05)
    bx0 = burbuja_padding
    by0 = burbuja_padding
    bx1 = size - burbuja_padding
    by1 = size - burbuja_padding
    radio_burbuja = int(size * 0.18)
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=radio_burbuja, fill=BLANCO)

    cx = (bx0 + bx1) // 2
    cy = (by0 + by1) // 2
    dibujar_candado(draw, cx, cy, int(size * 0.55), VERDE_OSCURO)
    return img


if __name__ == "__main__":
    icon = crear_icon(1024, con_fondo=True)
    icon.save("icon.png", "PNG", optimize=True)
    print("OK icon.png 1024x1024")

    icon_fg = crear_icon(1024, con_fondo=False)
    icon_fg.save("icon_foreground.png", "PNG", optimize=True)
    print("OK icon_foreground.png 1024x1024 (sin fondo)")

    splash = crear_splash(512)
    splash.save("splash.png", "PNG", optimize=True)
    print("OK splash.png 512x512")
