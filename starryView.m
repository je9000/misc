/*

 Mostly copied from Evan Green's Windows version: https://code.google.com/p/starrynight/
 
 Copyright John Eaglesham. Licensed under the BSD 3-Clause License.
 
 */

#import "starryView.h"

@implementation starryView

struct a_pixel  {
    unsigned char alpha;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} __attribute__((packed));

NSSize size;
struct a_pixel SnBuildingColor;
NSBitmapImageRep *ns_image = nil;
struct a_pixel airplaneColor;
struct a_pixel BLACK_PIXEL;
CGColorSpaceRef CGcolorSpace;
CGContextRef CGcontext;

struct a_pixel *image_data;
#define IMAGE_BPP 4
ULONG BytesPerRow;

#define BOOLEAN bool
#define VOID void
#define UCHAR unsigned char
#define FLASHER_SIZE 5
#define RESET_INTERVAL 5 * 60 * 1000 // 5 minutes in milliseconds

bool AirplaneActive = false;
ULONG AirplaneStartY = 0;
ULONG AirplaneTime = 0;
ULONG AirplaneMaxSpeedX = 2;
ULONG AirplaneMinSpeedX = 1;
ULONG AirplaneDuration = 0;
ULONG AirplaneVelocityX = 0;
int AirplaneDirectionX = 0;
ULONG MaxAirplanePeriodMs = 2000;
ULONG MinAirplanePeriodMs = 1000;
ULONG MaxAirplaneDuration = 30000;

#define BUILDING_STYLE_COUNT 6
#define TILE_HEIGHT 8
#define TILE_WIDTH 8
typedef struct _BUILDING {
    ULONG Style;
    ULONG Height;
    ULONG Width;
    ULONG BeginX;
    ULONG ZCoordinate;
} BUILDING, *PBUILDING;

ULONG SnStarsPerUpdate = 2;
ULONG SnBuildingPixelsPerUpdate = 4;
ULONG SnBuildingCount = 100;
ULONG SnBuildingHeightPercent = 35;
ULONG SnMinBuildingWidth = 5;
ULONG SnMaxBuildingWidth = 18;
ULONG SnMinRainWidth = 1;
ULONG SnMaxRainWidth = 4;
ULONG SnRainDropsPerUpdate = 1;
BOOLEAN SnFlasherEnabled = TRUE;
ULONG SnFlasherPeriodMs = 2000;
ULONG SnMaxShootingStarPeriodMs = 25000;
ULONG SnMinShootingStarPeriodMs = 10000;
ULONG SnMaxShootingStarDurationMs = 1000;
float SnMaxShootingStarSpeedX = 2.0;
float SnMinShootingStarSpeedY = 0.1;
float SnMaxShootingStarSpeedY = 2.0;
ULONG SnMaxShootingStarWidth = 4;

//
// Starry Night State.
//

ULONG SnScreenWidth = 0;
ULONG SnScreenHeight = 0;
BOOLEAN SnClear = TRUE;
PBUILDING SnBuilding = NULL;
ULONG SnFlasherX = 0;
ULONG SnFlasherY = 0;

//
// Starry Night Timing State.
//

ULONG SnTotalTimeMs = RESET_INTERVAL + 1;
ULONG SnFlasherTime = 0;
BOOLEAN SnFlasherOn = FALSE;
ULONG SnShootingStarTime = 0;
BOOLEAN SnShootingStarActive = FALSE;
ULONG SnShootingStarStartX = 0;
ULONG SnShootingStarStartY = 0;
float SnShootingStarVelocityX = 0.0;
float SnShootingStarVelocityY = 0.0;
ULONG SnShootingStarDuration = 0;

//
// Starry Night building styles. Buildings are made up of tiled 8x8 blocks.
//

UCHAR SnBuildingTiles[BUILDING_STYLE_COUNT][TILE_HEIGHT][TILE_WIDTH] = {
    {
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 1, 0, 0, 1, 1, 0, 0},
        {1, 1, 0, 0, 1, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {0, 1, 0, 1, 0, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 0, 0, 0, 1, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {0, 1, 1, 0, 1, 1, 0, 0},
        {0, 1, 1, 0, 1, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
};


- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    srand((unsigned int)time(NULL));
    
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/10.0];
    }
    
    size = [self bounds].size;
    /*
    SnBuildingColor = [NSColor colorWithRed:248/255.0
                                        green:241/255.0
                                        blue:3/255.0
                                        alpha:1.0];
     */
    SnBuildingColor = RGB(248, 241, 3);
    
    airplaneColor = RGB(255, 255, 255);
    BLACK_PIXEL = RGB(0, 0, 0);
    SnScreenHeight = size.height;
    SnScreenWidth = size.width;
    BytesPerRow = SnScreenWidth * IMAGE_BPP;
    
    image_data = malloc(SnScreenWidth * SnScreenHeight * IMAGE_BPP);
    if (!image_data) exit(1);
    
    CGcolorSpace = CGColorSpaceCreateDeviceRGB();
    CGcontext = CGBitmapContextCreate(image_data, SnScreenWidth, SnScreenHeight,
                                      8, SnScreenWidth * IMAGE_BPP, CGcolorSpace,
                                      kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big
                                     );
    
    
    //
    // Sanity check.
    //
    
    if (SnMinBuildingWidth == 0) {
        SnMinBuildingWidth = 1;
    }
    
    if (SnMaxBuildingWidth < SnMinBuildingWidth) {
        SnMaxBuildingWidth = SnMinBuildingWidth + 1;
    }
    
    
    SnBuilding = malloc(sizeof(BUILDING) * SnBuildingCount);
    if (SnBuilding) {
        InitBuildings();
        
        AirplaneActive = FALSE;
        AirplaneTime = (rand() % MaxAirplanePeriodMs) + MinAirplanePeriodMs;
        
        SnShootingStarActive = FALSE;
        SnShootingStarTime = (rand() % SnMaxShootingStarPeriodMs) + SnMinShootingStarPeriodMs;
        
        return self;
    }
    
    return nil;
}

void InitBuildings() {
    ULONG BuildingIndex;
    ULONG FlasherBuilding = 0;
    ULONG Index2;
    ULONG MaxActualHeight;
    ULONG MaxHeight;
    ULONG MinX;
    ULONG MinXIndex;
    float RandomHeight;
    BUILDING Swap;
    
    //
    // Determine the maximum height of a building.
    //
    
    MaxHeight =
    ((SnScreenHeight * SnBuildingHeightPercent) / 100) / TILE_HEIGHT;
    
    MaxActualHeight = 0;
    for (BuildingIndex = 0;
         BuildingIndex < SnBuildingCount;
         BuildingIndex += 1) {
        
        SnBuilding[BuildingIndex].Style = rand() % BUILDING_STYLE_COUNT;
        
        //
        // Squaring the random height makes for a more interesting distribution
        // of buildings.
        //
        
        RandomHeight = (float)rand() / (float)RAND_MAX;
        SnBuilding[BuildingIndex].Height =
        RandomHeight * RandomHeight * (float)MaxHeight;
        
        SnBuilding[BuildingIndex].Height += 1;
        SnBuilding[BuildingIndex].Width =
        SnMinBuildingWidth +
        (rand() % (SnMaxBuildingWidth - SnMinBuildingWidth));
        
        SnBuilding[BuildingIndex].BeginX = rand() % SnScreenWidth;
        SnBuilding[BuildingIndex].ZCoordinate = BuildingIndex + 1;
        
        //
        // The tallest building on the landscape gets the flasher.
        //
        
        if (SnBuilding[BuildingIndex].Height > MaxActualHeight) {
            MaxActualHeight = SnBuilding[BuildingIndex].Height;
            FlasherBuilding = BuildingIndex;
        }
    }
    
    //
    // Determine the flasher coordinates. The flasher goes at the center of the
    // top of the tallest building.
    //
    
    SnFlasherOn = FALSE;
    SnFlasherTime = 0;
    SnFlasherX = SnBuilding[FlasherBuilding].BeginX +
    (SnBuilding[FlasherBuilding].Width * TILE_WIDTH / 2);
    
    SnFlasherY = SnScreenHeight -
    (SnBuilding[FlasherBuilding].Height * TILE_HEIGHT);
    
    //
    // Sort the buildings by X coordinate.
    //

    for (BuildingIndex = 0;
         BuildingIndex < SnBuildingCount - 1;
         BuildingIndex += 1) {
        
        //
        // Find the building with the lowest X coordinate.
        //
        
        MinX = SnScreenWidth;
        MinXIndex = -1;
        for (Index2 = BuildingIndex; Index2 < SnBuildingCount; Index2 += 1) {
            if (SnBuilding[Index2].BeginX < MinX) {
                MinX = SnBuilding[Index2].BeginX;
                MinXIndex = Index2;
            }
        }
        
        //
        // Swap it into position.
        //
        
        if (BuildingIndex != MinXIndex) {
            Swap = SnBuilding[BuildingIndex];
            SnBuilding[BuildingIndex] = SnBuilding[MinXIndex];
            SnBuilding[MinXIndex] = Swap;
        }
    }

}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    // Causes a crash! ahh
    //CGContextRelease(CGcontext);
    //CGColorSpaceRelease(CGcolorSpace);
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

/*void ClearScreen()
{
    NSBezierPath *path;
    NSRect rect;
    
    NSColor *color;
    
    InitBuildings();

    rect.origin = NSMakePoint (0, 0);
    
    rect.size = NSMakeSize( size.width, size.height );
    path = [NSBezierPath bezierPathWithRect:rect];

    color = [NSColor blackColor];
    [color set];
    [path fill];
}*/

void ClearScreen()
{
    memset(image_data, 0, SnScreenHeight * SnScreenWidth * IMAGE_BPP);
}

// Helper function that mimics what Windows has.
/*void SetPixel(float x, float y, NSColor *color, int sz)
{
    NSBezierPath *path;
    NSRect rect;

    // I guess Windows and OSX screen Y-coordinates are reversed,
    // so make up for that here by inverting the Y.
    rect.origin = NSMakePoint (x, size.height - y);
    rect.size = NSMakeSize( sz, sz );

    path = [NSBezierPath bezierPathWithRect:rect];
    
    [color set];
    
    [path fill];
}*/

void SetPixel(unsigned int x, unsigned int y, struct a_pixel color, unsigned int sz)
{
    size_t offset;
    
    
    for(int px = x; px < x + sz && px < SnScreenWidth; px++) {
        for(int py = y; py < y + sz && py < SnScreenHeight; py++) {
            offset = (py * SnScreenWidth) + px;
            if (offset > SnScreenWidth * SnScreenHeight) exit(4);
    /*
            image_data[offset].red = color.red;
            image_data[offset].green = color.green;
            image_data[offset].blue = color.blue;
            image_data[offset].alpha = 255;
     */
            ((u_int32_t *) image_data)[offset] = *((u_int32_t *) &color);
        }
    }
}

/*
void DrawLine(int fromx, int fromy, int tox, int toy, float width, NSColor *color)
{
    return;
    NSBezierPath* thePath = [NSBezierPath bezierPath];
    [thePath moveToPoint:NSMakePoint(fromx, size.height - fromy)]; // Reversed Y, remember?
    [thePath setLineWidth:width];
    [thePath lineToPoint:NSMakePoint(tox, size.height - toy)];
    [color setStroke];
    [thePath stroke];
}
*/

void DrawLine(int fromx, int fromy, int tox, int toy, float width, NSColor *color)
{
    CGContextSetStrokeColorWithColor(CGcontext, color.CGColor);
    CGContextSetLineWidth(CGcontext, width);
    CGContextMoveToPoint(CGcontext, fromx, fromy);
    CGContextAddLineToPoint(CGcontext, tox, toy);
    CGContextStrokePath(CGcontext);
}

struct a_pixel RGB(unsigned char r, unsigned char g, unsigned char b)
{
    struct a_pixel p;
    p.red = r;
    p.green = g;
    p.blue = b;
    p.alpha = 255;
    return p;
}

NSBitmapImageRep* makeImage(void *data)
{
    CGImageRef imageRef = CGBitmapContextCreateImage(CGcontext);
    NSBitmapImageRep *result = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return result;
}

- (void)animateOneFrame
{
    SnpUpdate([self animationTimeInterval] * 1000);
    NSRect imageRect = NSMakeRect(0, 0, SnScreenWidth, SnScreenHeight);
    
    ns_image = makeImage(image_data);
    [ns_image drawInRect:imageRect];
    /*
    ns_image = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:SnScreenWidth pixelsHigh:SnScreenHeight bitsPerSample:8 samplesPerPixel:(IMAGE_BPP) hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat bytesPerRow:0 bitsPerPixel:(IMAGE_BPP * 8)];
    if (ns_image == nil) exit(1);
    
    unsigned char *new_image = [ns_image bitmapData];
    memcpy(new_image, image_data, SnScreenWidth * SnScreenHeight * IMAGE_BPP);
    
    [ns_image drawInRect:imageRect];
    */
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

///////////////////////////


VOID
SnpUpdate (
           ULONG ms
           )

/*++
 
 Routine Description:
 
 This routine updates the Starry Night runtime.
 
 Arguments:
 
 ms - Supplies the number of miliseconds that have gone by since
 the last update.
 
 Return Value:
 
 TRUE on success.
 
 FALSE if a serious failure occurred.
 
 --*/

{
    
    //
    // Update main time.
    //
    
    SnTotalTimeMs += ms;
    
    //
    // If the window has not been set up, clear everything now.
    //
    
    if (SnTotalTimeMs > RESET_INTERVAL) {
        ClearScreen();
        SnTotalTimeMs = 0;
    }
    
    SnpDrawStars();
    SnpDrawBuildings();
    SnpDrawRain();
    SnpDrawShootingStar(ms);
    SnpDrawFlasher(ms);
    SnpDrawAirplane(ms);
}

VOID
SnpDrawStars ()

/*++
 
 Routine Description:
 
 This routine draws stars to the sky.
 
 Arguments:
 
 Dc - Supplies the device context to draw stars to.
 
 Return Value:
 
 None.
 
 --*/

{
    
    float RandomY;
    ULONG StarIndex;
    ULONG StarX;
    ULONG StarY;
    
    //
    // Randomly sprinkle a certain number of stars on the screen.
    //
    
    StarIndex = 0;
    while (StarIndex < SnStarsPerUpdate) {
        StarX = rand() % SnScreenWidth;
        
        //
        // Squaring the Y coordinate puts more stars at the top and gives it
        // a more realistic (and less static-ish) view.
        //
        
        RandomY = (float)rand() / (float)RAND_MAX;
        StarY = (ULONG)(RandomY * RandomY * (float)SnScreenHeight);
        if (SnpGetTopBuilding(StarX, StarY) != -1) {
            continue;
        }
        
        int w = (rand() % 236) + 20;
        
        SetPixel(StarX,
                 StarY,
                 //RGB(rand() % 180, rand() % 180, rand() % 256)
                 RGB(w, w, w),
                 1
        );
        
        StarIndex += 1;
    }
    
    return;
}

VOID
SnpDrawBuildings (
                  )

/*++
 
 Routine Description:
 
 This routine draws little lights into buildings, each one a hard little
 worker.
 
 Arguments:
 
 Dc - Supplies the device context to draw stars to.
 
 Return Value:
 
 None.
 
 --*/

{
    
    ULONG Building;
    ULONG BuildingHeightRange;
    ULONG BuildingHeightOffset;
    ULONG PixelsOn;
    ULONG PotentialX;
    ULONG PotentialY;
    ULONG Style;
    ULONG TileX;
    ULONG TileY;
    
    BuildingHeightRange = SnScreenHeight - SnFlasherY;
    BuildingHeightOffset = SnFlasherY;
    PixelsOn = 0;
    while (PixelsOn < SnBuildingPixelsPerUpdate) {
        PotentialX = rand() % SnScreenWidth;
        PotentialY = BuildingHeightOffset + (rand() % BuildingHeightRange);
        Building = SnpGetTopBuilding(PotentialX, PotentialY);
        if (Building == -1) {
            continue;
        }
        
        TileX = (PotentialX - SnBuilding[Building].BeginX) % TILE_WIDTH;
        TileY = PotentialY % TILE_HEIGHT;
        Style = SnBuilding[Building].Style;
        if (SnBuildingTiles[Style][TileY][TileX] == 0) {
            continue;
        }
        
        SetPixel(PotentialX, PotentialY, SnBuildingColor, 1);
        PixelsOn += 1;
    }
    
    return;
}

ULONG
SnpGetTopBuilding (
                   ULONG ScreenX,
                   ULONG ScreenY
                   )

/*++
 
 Routine Description:
 
 This routine determines which building the given pixel is in.
 
 Arguments:
 
 ScreenX - Supplies the X coordinate, in screen space.
 
 ScreenY - Supplies the Y coordinate, in screen space.
 
 Return Value:
 
 Returns the building index at the given screen location, or -1 if the
 coordinate is filled with sky.
 
 --*/

{
    
    ULONG Building;
    ULONG BuildingRight;
    ULONG BuildingTop;
    ULONG FrontBuilding;
    ULONG MaxZ;
    
    FrontBuilding = -1;
    MaxZ = 0;
    for (Building = 0; Building < SnBuildingCount; Building += 1) {
        
        //
        // The buildings are sorted by X coordinate. If this building starts
        // to the right of the pixel in question, none of the rest intersect.
        //
        
        if (SnBuilding[Building].BeginX > ScreenX) {
            break;
        }
        
        //
        // Check to see if the pixel is inside this building.
        //
        
        BuildingTop = SnScreenHeight -
        (SnBuilding[Building].Height * TILE_HEIGHT);
        
        BuildingRight = SnBuilding[Building].BeginX +
        (SnBuilding[Building].Width * TILE_WIDTH);
        
        if ((ScreenX >= SnBuilding[Building].BeginX) &&
            (ScreenX < BuildingRight) &&
            (ScreenY > BuildingTop)) {
            
            //
            // If this is the front-most building, mark it as the new winner.
            //
            
            if (SnBuilding[Building].ZCoordinate > MaxZ) {
                FrontBuilding = Building;
                MaxZ = SnBuilding[Building].ZCoordinate;
            }
        }
    }
    
    return FrontBuilding;
}

VOID
SnpDrawRain (

             )

/*++
 
 Routine Description:
 
 This routine draws black rain onto the sky, giving the illusion that stars
 and lights are going back off.
 
 Arguments:
 
 Dc - Supplies the context to draw the black rain on.
 
 Return Value:
 
 None.
 
 --*/

{
    ULONG DropIndex;
    ULONG LineWidth;
    ULONG RainX;
    ULONG RainY;
    ULONG D;
    
    for (DropIndex = 0; DropIndex < SnRainDropsPerUpdate; DropIndex += 1) {
        LineWidth = SnMinRainWidth + (rand() % (SnMaxRainWidth - SnMinRainWidth));
        
        RainX = rand() % SnScreenWidth;
        RainY = rand() % SnScreenHeight;
        D = rand() % 16;
        
        DrawLine(RainX, RainY, RainX + D, RainY + D, LineWidth, [NSColor blackColor]);
    }
    return;
}

VOID
SnpDrawFlasher (
                ULONG TimeElapsed
                )

/*++
 
 Routine Description:
 
 This routine draws the flasher, if enabled.
 
 Arguments:
 
 TimeElapsed - Supplies the time elapsed since the last update, in
 milliseconds.
 
 Dc - Supplies the context to draw the flasher on.
 
 Return Value:
 
 None.
 
 --*/

{
    BOOLEAN BlackOutFlasher;
 
    BlackOutFlasher = FALSE;
    
    if (SnFlasherEnabled == FALSE) {
        SnFlasherOn = FALSE;
        return;
    }
    
    SnFlasherTime += TimeElapsed;
    if (SnFlasherTime >= SnFlasherPeriodMs) {
        SnFlasherTime -= SnFlasherPeriodMs;
        if (SnFlasherOn == FALSE) {
            SnFlasherOn = TRUE;
            
        } else {
            SnFlasherOn = FALSE;
            BlackOutFlasher = TRUE;
        }
    }
    
    //
    // Create the pen and select it.
    //
    
    if ((SnFlasherOn != FALSE) || (BlackOutFlasher != FALSE)) {
        struct a_pixel color;
        if (SnFlasherOn != FALSE) {
            color = RGB(190, 0, 0);
        } else {
            color = RGB(0, 0, 0);
        }
        SetPixel(SnFlasherX, SnFlasherY, color, FLASHER_SIZE);
    }

    return;
}

VOID
SnpDrawShootingStar (
                     ULONG TimeElapsed
                     )

/*++
 
 Routine Description:
 
 This routine updates any shooting stars on the screen, for those watching
 very closely.
 
 Arguments:
 
 TimeElapsed - Supplies the time elapsed since the last update, in
 milliseconds.
 
 Dc - Supplies the context to draw the flasher on.
 
 Return Value:
 
 None.
 
 --*/

{
    ULONG CurrentX;
    ULONG CurrentY;
    ULONG NewX;
    ULONG NewY;
    ULONG building_height;

    static ULONG LastCurrentX = 0, LastCurrentY, LastNewX, LastNewY;
    
    //
    // If there is no shooting star now, count time until the decided period
    // has ended.
    //
    
    if (SnShootingStarActive == FALSE) {
        
        //
        // If this causes the shooting star time to fire, set up the shooting
        // star.
        //
        
        if (SnShootingStarTime <= TimeElapsed) {
            SnShootingStarTime = 0;
            SnShootingStarActive = TRUE;
            building_height = SnBuildingHeightPercent / 100.0 * SnScreenHeight;
            
            //
            // The shooting star should start somewhere between the top of the
            // buildings and the top of the screen.
            //
            
            SnShootingStarStartX = rand() % SnScreenWidth;
            SnShootingStarStartY = (rand() % (SnScreenHeight - building_height)) + building_height;
            SnShootingStarDuration = (rand() % SnMaxShootingStarDurationMs) + 1;
            SnShootingStarVelocityX = (((float)rand() / (float)RAND_MAX) *
                                       (2.0 * SnMaxShootingStarSpeedX)) -
                                        SnMaxShootingStarSpeedX;
            
            SnShootingStarVelocityY = -1 * (((float)rand() / (float)RAND_MAX) *
                                       (SnMaxShootingStarSpeedY -
                                        SnMinShootingStarSpeedY)) +
                                        SnMinShootingStarSpeedY;
            
            //
            // No shooting star now, keep counting down.
            //
            
        } else {
            SnShootingStarTime -= TimeElapsed;
            return;
        }
    }
    
    //
    // Draw the shooting star line from the current location to the next
    // location.
    //
    
    //struct a_pixel starColor = RGB(120, 120, 120);
    
    CurrentX = SnShootingStarStartX +
    ((float)SnShootingStarTime * SnShootingStarVelocityX);
    
    CurrentY = SnShootingStarStartY +
    ((float)SnShootingStarTime * SnShootingStarVelocityY);
    
    //
    // Draw background from the start to the current value.
    //
    
    if (LastCurrentX && LastCurrentY) DrawLine(LastCurrentX, LastCurrentY, LastNewX, LastNewY, 3, [NSColor blackColor]);
    
    
    if (SnShootingStarTime < SnShootingStarDuration) {
        NewX = CurrentX + ((float)TimeElapsed * SnShootingStarVelocityX);
        NewY = CurrentY + ((float)TimeElapsed * SnShootingStarVelocityY);
        
        //
        // If the shooting star is about to fall behind a building, cut it off
        // now. Otherwise, draw it.
        //
        
        if (SnpGetTopBuilding(NewX, NewY) != -1) {
            SnShootingStarTime = SnShootingStarDuration;
            LastCurrentX = LastCurrentY = 0;
            
        } else {
            DrawLine(CurrentX, CurrentY, NewX, NewY, 1, [NSColor whiteColor]);
            LastCurrentX = CurrentX;
            LastCurrentY = CurrentY;
            LastNewX = NewX;
            LastNewY = NewY;
        }
    }

    //
    // Update the counters. If there is more time on the shooting star, just
    // update time.
    //
    
    if (SnShootingStarTime < SnShootingStarDuration) {
        SnShootingStarTime += TimeElapsed;
        
        //
        // The shooting star is sadly over. Reset the counters and patiently wait
        // for the next one.
        //
        
    } else {
        SnShootingStarActive = FALSE;
        SnShootingStarTime = (rand() % SnMaxShootingStarPeriodMs) + SnMinShootingStarPeriodMs;
    }
}

VOID
SnpDrawAirplane (
                     ULONG TimeElapsed
                     )

/*++
 
 Routine Description:
 
 This routine updates any shooting stars on the screen, for those watching
 very closely.
 
 Arguments:
 
 TimeElapsed - Supplies the time elapsed since the last update, in
 milliseconds.
 
 Dc - Supplies the context to draw the flasher on.
 
 Return Value:
 
 None.
 
 --*/

{
    unsigned int CurrentX;
    float RandomY;
    ULONG building_height;
    
    static unsigned int LastCurrentX = -1;
    static bool LastCurrentXValid = false;
    static unsigned int calls = 0;
    static bool light_off = false;
    
    //
    // If there is no airplane star now, count time until the decided period
    // has ended.
    //
    
    if (AirplaneActive == FALSE) {
        
        //
        // If this causes the airplane time to fire, set up the airplane.
        //
        
        if (AirplaneTime <= TimeElapsed) {
            AirplaneTime = 0;
            AirplaneActive = TRUE;
            building_height = ((SnBuildingHeightPercent) / 100.0 * SnScreenHeight) * 1.2;

            //
            // The airplane should start somewhere between the top of the
            // buildings and the top of the screen.
            //
            RandomY = (float)rand() / (float)RAND_MAX;
            AirplaneStartY = SnScreenHeight - ((rand() % (SnScreenHeight - building_height)) + building_height);
            AirplaneVelocityX = (rand() % AirplaneMaxSpeedX) + AirplaneMinSpeedX;
            if (rand() % 2 == 0) {
                AirplaneDirectionX = -1;
                LastCurrentX = SnScreenWidth;
            } else {
                AirplaneDirectionX = 1;
                LastCurrentX = 0;
            }
            LastCurrentXValid = true;
            calls = 0;
        } else {
            AirplaneTime -= TimeElapsed;
            return;
        }
    }
    
    CurrentX = (ULONG) LastCurrentX + AirplaneVelocityX * AirplaneDirectionX;
    
    if (LastCurrentXValid && LastCurrentX < SnScreenWidth) {
        SetPixel(LastCurrentX, AirplaneStartY, BLACK_PIXEL, 2);
    }

    if (CurrentX < SnScreenWidth) {
        if (calls % 10 == 0) light_off = !light_off;
        if (!light_off) SetPixel(CurrentX, AirplaneStartY, airplaneColor, 2);
        AirplaneTime += TimeElapsed;
        LastCurrentX = CurrentX;
    } else {
        AirplaneActive = FALSE;
        AirplaneTime = (rand() % MaxAirplanePeriodMs) + MinAirplanePeriodMs;
        LastCurrentXValid = false;
    }
    calls++;
}

@end
