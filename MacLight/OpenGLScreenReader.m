 /*
 
 File: OpenGLScreenReader.m
 
 Abstract: OpenGLScreenReader class implementation. Contains
            OpenGL code which creates a full-screen OpenGL context
            to use for rendering, then calls glReadPixels to read the 
            actual screen bits.
 
 Version: 1.0
 
 */ 
 
#import "OpenGLScreenReader.h"

@implementation OpenGLScreenReader

// ---------- Constants ----------

const uint_fast8_t fade = 33;
const uint_fast8_t min_brightness = 128;

const uint_fast8_t displays[][3] = {
    {0,21,15}   // 21 leds wide, 15 leds high
//    {1,21,15} // hypothetical second display
};

// setup led array
const uint_fast8_t leds[NUM_LED][3] = {
    {0,0,14}, {0,0,13}, {0,0,12}, {0,0,11}, {0,0,10}, {0,0,9}, {0,0,8},
    {0,0,7}, {0,0,6}, {0,0,5}, {0,0,4}, {0,0,3}, {0,0,2}, {0,0,1},                   // Left edge
    
    {0,0,0}, {0,1,0}, {0,2,0}, {0,3,0}, {0,4,0}, {0,5,0}, {0,6,0},                   // Top edge
    {0,7,0}, {0,8,0}, {0,9,0}, {0,10,0}, {0,11,0}, {0,12,0}, {0,13,0},               // More top edge
    {0,14,0}, {0,15,0}, {0,16,0}, {0,17,0}, {0,18,0}, {0,19,0}, {0,20,0},            // even more top edge
    
    {0,20,1}, {0,20,2}, {0,20,3}, {0,20,4}, {0,20,5}, {0,20,6}, {0,20,7},         // Right edge
    {0,20,8}, {0,20,9}, {0,20,10}, {0,20,11}, {0,20,12}, {0,20,13}, {0,20,14},
};

#pragma mark ---------- Initialization ----------

-(id) init
{
    if ((self = [super init]))
    {
        // get image
        CGImageRef image = CGDisplayCreateImage(kCGDirectMainDisplay);
        
        size_t width  = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        
        size_t bpr = CGImageGetBytesPerRow(image);
        size_t bpp = CGImageGetBitsPerPixel(image);
        size_t bpc = CGImageGetBitsPerComponent(image);
        size_t bytes_per_pixel = bpp / bpc;

        // fill previous frame
        for (int i = 0; i < NUM_LED; i++) {
            previous_frame[i][0] = previous_frame[i][1] = previous_frame[i][2] = min_brightness / 3;
        }
        
        // precompute gamma
        float f;
        for(int i = 0; i < 256; i++) {
            f           = pow((float)i / 255.0, 2.8);
            gamma[i][0] = f * 255.0;
            gamma[i][1] = f * 240.0;
            gamma[i][2] = f * 220.0;
        }
        
        // Precompute locations of every pixel to read when downsampling.
        // Saves a bunch of math on each frame, at the expense of a chunk
        // of RAM.  Number of samples is now fixed at 256; this allows for
        // some crazy optimizations in the downsampling code.
        for(int i = 0; i < NUM_LED; i++) { // For each LED...
            int d = leds[i][0]; // Corresponding display index
            
            // Precompute columns, rows of each sampled point for this LED
            int x[16];
            int y[16];
            float range = (float)width / (float)displays[d][1];
            float step  = range / 16.0;
            float start = range * (float)leds[i][1] + step * 0.5;
            for(int col = 0; col < 16; col++)
                x[col] = (int)(start + step * (float)col);
            
            range = (float)height / (float)displays[d][2];
            step  = range / 16.0;
            start = range * (float)leds[i][2] + step * 0.5;
            for(int row = 0; row < 16; row++)
                y[row] = (int)(start + step * (float)row);

            // Get offset to each pixel within full screen capture
            for(int row = 0; row < 16; row++) {
                for(int col = 0; col < 16; col++) {
                    pixel_offset[i][row * 16 + col] = y[row] * bpr + x[col] * bytes_per_pixel;
                }
            }
        }
        CFRelease(image);
    }
    return self;
}

#pragma mark ---------- Screen Reader  ----------


- (uint_fast8_t *)readScreenBuffer
{
    CGImageRef image = CGDisplayCreateImage(kCGDirectMainDisplay);
    
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    NSData* data = (id)CGDataProviderCopyData(provider);
    [data autorelease];
    const uint8_t* bytes = [data bytes];
    
    int weight = 257 - fade; // 'Weighting factor' for new frame vs. old
    int j;
    
    // This computes a single pixel value filtered down from a rectangular
    // section of the screen.  While it would seem tempting to use the native
    // image scaling in Processing/Java, in practice this didn't look very
    // good -- either too pixelated or too blurry, no happy medium.  So
    // instead, a "manual" downsampling is done here.  In the interest of
    // speed, it doesn't actually sample every pixel within a block, just
    // a selection of 256 pixels spaced within the block...the results still
    // look reasonably smooth and are handled quickly enough for video.
    
    // For each LED...
    for(int i = 0; i < NUM_LED; i++) {  
        uint_fast16_t r, g, b, sum, s2, deficit;
        r = g = b = 0;
        
        // ...pick 256 samples
        for(int sample = 0; sample < 256; sample++) {
            const uint8_t* pixel = &bytes[pixel_offset[i][sample]];
            r += pixel[2];
            g += pixel[1];
            b += pixel[0];
        }

        // Blend new average with the value from the prior frame
        led_color[i][0] = ((((r >> 8) & 0xff) * weight + previous_frame[i][0] * fade) >> 8);
        led_color[i][1] = ((((g >> 8) & 0xff) * weight + previous_frame[i][1] * fade) >> 8);
        led_color[i][2] = ((((b >> 8) & 0xff) * weight + previous_frame[i][2] * fade) >> 8);
        
        // Boost pixels that fall below the minimum brightness
        sum = led_color[i][0] + led_color[i][1] + led_color[i][2];
        if(sum < min_brightness) {
            if(sum == 0) { // To avoid divide-by-zero
                deficit = min_brightness / 3; // Spread equally to R,G,B
                led_color[i][0] += deficit;
                led_color[i][1] += deficit;
                led_color[i][2] += deficit;
            } else {
                deficit = min_brightness - sum;
                s2      = sum * 2;
                // Spread the "brightness deficit" back into R,G,B in proportion to
                // their individual contribition to that deficit.  Rather than simply
                // boosting all pixels at the low end, this allows deep (but saturated)
                // colors to stay saturated...they don't "pink out."
                led_color[i][0] += deficit * (sum - led_color[i][0]) / s2;
                led_color[i][1] += deficit * (sum - led_color[i][1]) / s2;
                led_color[i][2] += deficit * (sum - led_color[i][2]) / s2;
            }
        }
        
        // Apply gamma curve and place in serial output buffer
        j = 0;
        current_frame[i][j] = gamma[led_color[i][0]][0];
        j++;
        current_frame[i][j] = gamma[led_color[i][1]][1];
        j++;
        current_frame[i][j] = gamma[led_color[i][2]][2];

    }
    CFRelease(image);
    
    return current_frame;
}


#pragma mark ---------- Cleanup  ----------

-(void)dealloc
{    
//    // Get rid of GL context
//    [NSOpenGLContext clearCurrentContext];
//    // disassociate from full screen
//    [mGLContext clearDrawable];
//    // and release the context
//    [mGLContext release];
//	// release memory for screen data
//	free(mData);

    [super dealloc];
}

@end
