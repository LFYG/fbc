/*
 *  libgfx2 - FreeBASIC's alternative gfx library
 *	Copyright (C) 2005 Angelo Mottola (a.mottola@libero.it)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/*
 * circle.c -- CIRCLE statement
 *
 * chng: jan/2005 written [lillo]
 *
 */

#include "fb_gfx.h"


/*:::::*/
static void draw_scanline(FB_GFXCTX *ctx, int y, int x1, int x2, unsigned int color, int fill, char *filled)
{
	if ((y >= ctx->view_y) && (y < ctx->view_y + ctx->view_h)) {
		if (fill) {
			if ((x2 < ctx->view_x) || (x1 >= ctx->view_x + ctx->view_w) || (filled[y - ctx->view_y]))
				return;
			filled[y - ctx->view_y] = TRUE;
			x1 = MAX(x1, ctx->view_x);
			x2 = MIN(x2, ctx->view_x + ctx->view_w - 1);
			ctx->pixel_set(ctx->line[y] + (x1 * __fb_gfx->bpp), color, x2 - x1 + 1);
		}
		else {
			if ((x1 >= ctx->view_x) && (x1 < ctx->view_x + ctx->view_w))
				ctx->put_pixel(ctx, x1, y, color);
			if ((x2 >= ctx->view_x) && (x2 < ctx->view_x + ctx->view_w))
				ctx->put_pixel(ctx, x2, y, color);
		}
	}
}


/*:::::*/
static void draw_ellipse(FB_GFXCTX *ctx, int x, int y, float a, float b, unsigned int color, int fill)
{
	int d, x1, y1, x2, y2;
	long long dx, dy, aq, bq, r, rx, ry;
	char filled[ctx->view_h];

	x1 = x - a;
	x2 = x + a;
	y1 = y2 = y;
	fb_hMemSet(filled, 0, ctx->view_h);
	
	if (!b) {
		draw_scanline(ctx, y, x1, x2, color, TRUE, filled);
		return;
	}
	else
		draw_scanline(ctx, y, x1, x2, color, fill, filled);
	
	aq = a * a;
	bq = b * b;
	dx = aq << 1;
	dy = bq << 1;
	r = a * bq;
	rx = r << 1;
	ry = 0;
	d = a;
	
	while (d > 0) {
		if (r > 0) {
			y1++;
			y2--;
			ry += dx;
			r -= ry;
		}
		if (r <= 0) {
			d--;
			x1++;
			x2--;
			rx -= dy;
			r += rx;
		}
		draw_scanline(ctx, y1, x1, x2, color, fill, filled);
		draw_scanline(ctx, y2, x1, x2, color, fill, filled);
	}
}


/*:::::*/
static void get_arc_point(float angle, float a, float b, int *x, int *y)
{
	float c, s;
	
	c = cos(angle) * a;
	s = sin(angle) * b;
	if (c >= 0)
		*x = (int)(c + 0.5);
	else
		*x = (int)(c - 0.5);
	if (s >= 0)
		*y = (int)(s + 0.5);
	else
		*y = (int)(s - 0.5);
}


/*:::::*/
FBCALL void fb_GfxEllipse(void *target, float fx, float fy, float radius, unsigned int color, float aspect, float start, float end, int fill, int coord_type)
{
	FB_GFXCTX *context = fb_hGetContext();
	int x, y, x1, y1, top, bottom;
	unsigned int orig_color;
	float a, b, increment;
	
	if (!__fb_gfx)
		return;
	
	orig_color = color;
	if (color == DEFAULT_COLOR)
		color = context->fg_color;
	else
		color = fb_hFixColor(color);
	
	fb_hPrepareTarget(context, target, color);
	
	fb_hFixRelative(context, coord_type, &fx, &fy, NULL, NULL);
	
	fb_hTranslateCoord(context, fx, fy, &x, &y);
	
	if (aspect == 0.0)
		aspect = (4.0 / 3.0) * ((float)__fb_gfx->h / (float)__fb_gfx->w);

	if (aspect > 1.0) {
		a = (radius / aspect);
		b = radius;
	}
	else {
		a = radius;
		b = (radius * aspect);
	}
	if (context->flags & CTX_WINDOW_ACTIVE) {
		a *= (context->view_w / (context->win_w - 1));
		b *= (context->view_h / (context->win_h - 1));
	}
	
	if ((start != 0.0) || (end != 3.141593f * 2.0)) {
		
		if (start < 0) {
			start = -start;
			get_arc_point(start, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			fb_GfxLine(target, x, y, x1, y1, orig_color, LINE_TYPE_LINE, 0xFFFF, COORD_TYPE_AA);
		}
		if (end < 0) {
			end = -end;
			get_arc_point(end, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			fb_GfxLine(target, x, y, x1, y1, orig_color, LINE_TYPE_LINE, 0xFFFF, COORD_TYPE_AA);
		}
		
		while (end < start)
			end += 2 * PI;
		while (end - start > 2 * PI)
			start += 2 * PI;
		
		increment = 1 / (sqrt(a) * sqrt(b) * 1.5);
		
		DRIVER_LOCK();
		
		top = bottom = y;
		for (; start < end + (increment / 2); start += increment) {
			get_arc_point(start, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			if ((x1 < context->view_x) || (x1 >= context->view_x + context->view_w) ||
			    (y1 < context->view_y) || (y1 >= context->view_y + context->view_h))
				continue;
			context->put_pixel(context, x1, y1, color);
			if (y1 > bottom)
				bottom = y1;
			if (y1 < top)
				top = y1;
		}
	}
	else {
		DRIVER_LOCK();
		
		draw_ellipse(context, x, y, a, b, color, fill);
		top = y - b;
		bottom = y + b;
	}
	
	top = MID(0, top, context->view_h - 1);
	bottom = MID(0, bottom, context->view_h - 1);
	if( top > bottom )
		SWAP( top, bottom );
	SET_DIRTY(context, top, bottom - top + 1);
	
	DRIVER_UNLOCK();
}
