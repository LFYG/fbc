#include "QB_gfx_main.c"

FBCALL Uint32 fb_GfxPoint (float x, float y)
{
    Sint16 rx, ry;
    Uint8 r, g, b, bpp, *p;
    Uint32 pixel;

    SANITY_CHECK

    bpp = fb_GfxInfo.screen->format->BytesPerPixel;

    fb_GfxTransCoord(x, y, &rx, &ry);

    /*
     * Return -1 (8 bit) or DEFAULT color (> 8 bit) outside of VIEW
     */
    if ( (x < fb_GfxInfo.view.x) || (x > fb_GfxInfo.view.x + fb_GfxInfo.view.w-1) ||
         (y < fb_GfxInfo.view.y) || (y > fb_GfxInfo.view.y + fb_GfxInfo.view.h-1) )
    {
        if (bpp == 1)
            return 0xFFFFFFFF;
        else
            return DEFAULT_COLOR;
    }

    /* Calculate pixel address */
    p = (Uint8 *) fb_GfxInfo.screen->pixels + ry * fb_GfxInfo.screen->pitch + rx * bpp;

    /*
     * Lock the surface
     */
    if (SDL_MUSTLOCK(fb_GfxInfo.screen)) {
        if (SDL_LockSurface(fb_GfxInfo.screen) < 0) {
            return (-1);
        }
    }

    switch (bpp)
    {
    case 1:
        pixel = *p;
        break;
    case 2:
        pixel = *(Uint16 *) p;
        break;
    case 3:
        if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
            pixel = (p[0] << 16) + (p[1] << 8) + p[2];
        } else {
            pixel = p[0] + (p[1] << 8) + (p[2] << 16);
        }
        break;
    case 4:
        pixel = *(Uint32 *) p;
        break;
    }  /* switch */

    /*
     * Unlock surface
     */
    if (SDL_MUSTLOCK(fb_GfxInfo.screen)) {
        SDL_UnlockSurface(fb_GfxInfo.screen);
    }

    if (bpp > 1)
    {
        /* Convert to 0xRRGGBBAA format and return */
        SDL_GetRGB(pixel, fb_GfxInfo.screen->format, &r, &g, &b);
        return (r << 24) + (g << 16) + (b << 8) + 0xFF;
    }
    else
    {
        return pixel;
    }
}

