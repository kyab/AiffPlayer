//
//  SpectrumView3DOpenGL.m
//  AiffPlayer
//
//  Created by koji on 11/05/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView3DOpenGL.h"
#import "NSColor_extention.h"

#import "3d.h"
#import "glhelper.h"


struct SimpleVertex3{
	float x;
	float y;
	float z;
};

//lighting
static const GLfloat materialAmbient[4] = {0.3, 0.2, 0.1, 1.};
static const GLfloat materialDiffuse[4] = {0.6, 0.6, 0.6, 1.};
static const GLfloat materialSpecular[4] = {1., 0.9, 0.9, 1.};
static const GLfloat materialShininess[4] = {30., 30., 80., 0.8};	//from 0 to 128
static const GLfloat light0Ambient[4] = {0.9, 0.9, 0.9, 1.};	//光の当たらない部分の色(R,G,B,A) 光源から直接放射されるのではなく、周囲（環境）から一様に照らす光｡
static const GLfloat light0Diffuse[4] = {0.9, 0.9, 0.9, 1.};	//光源そのものの色		 (R,G,B,A)
static const GLfloat light0Specular[4] = {0.7, 0.7, 0.7, 1.};	//光の直接当たる部分の輝度 (R,G,B,A)
static const GLfloat light0Position[4] = {10.0, 10.0, 10.0, 1.};	//光源の位置


GLfloat m[16];
static GLuint displayList_Spectrum = 1;
void
drawGLString(GLfloat x, GLfloat y, GLfloat z, const char *string)
{
	int len, i;
	
	glRasterPos3f(x, y, z);
	len = (int) strlen(string);
	for (i = 0; i < len; i++) {
		glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, string[i]);
	}
}

static const int FFT_SIZE = 256;
static const int SPECTRUM3D_COUNT = 100;

@implementation SpectrumView3DOpenGL

@synthesize enabled = _enabled;
@synthesize log = _log;
@synthesize rotateByTrackball = _rotateByTrackball;

//for view instances created in Interface Builder(except NSCustomView Proxy) 
//initWithFrame not called. see: http://msyk.net/mdonline/msgbox/messageshow_54406.html
- (id)initWithFrame:(NSRect)frameRect{
	NSLog(@"SpectrumView3DOpenGL::initWithFrame");
	self = [super initWithFrame:frameRect];
	if (self){

	}
	NSAssert(false, @"this should be never called");
	return self;
}

-(void)awakeFromNib{
	NSLog(@"OpenGL awake from nib");
	
	[self setEnabled:YES];
	[self setLog:NO];
	[self setRotateByTrackball:YES];
	_aiff = nil;
	
	for (int i = 0 ; i < 4; i++){
		_trackballRotation[i] = 0.0f;
	}
	
	//initial rotation(trackball mode). copied from better looking values by NSLog("..", _worldRotation[0],,)
	_worldRotation[0] =  72.94f;
	_worldRotation[1] =  0.361f;
	_worldRotation[2] = -0.902f;
	_worldRotation[3] = -0.235f;
	
}


-(void)addRotateZ:(float) angle{
	[self rotate:angle forX:0.0 forY:0.0 forZ:1.0];
}
-(void)addRotateX:(float) angle{
	[self rotate:angle forX:1.0 forY:0.0 forZ:0.0];
}
-(void)addRotateY:(float) angle{
	[self rotate:angle forX:0.0 forY:1.0 forZ:0.0];
}

-(void)rotate:(float)angle forX:(float)x forY:(float)y forZ:(float)z{
	
	//create new rotation matrix, then multyply it to m
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	glRotatef(angle, x, y, z);
	glMultMatrixf(m);
	
	glGetFloatv(GL_MODELVIEW, m);
	glPopMatrix();
	
	NSLog(@"rotation added. angle = %f, x = %f ,y = %f ,z = %f", angle, x, y, z);
	[self setNeedsDisplay:YES];
}


-(void)setAiff:(id)aiff{
	_aiff = aiff;
	[_aiff addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self compileSpectrumsToDisplayList];
	[self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	
	if ([keyPath isEqual:@"selection"]){
		NSLog(@"Spectrum3D(OpenGL) observe change of selection");
		[self compileSpectrumsToDisplayList];
		[self setNeedsDisplay:YES];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


-(void)reshape{
	NSRect bounds = [self bounds];
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	//このビューの全面に表示。
	glViewport( (int)bounds.origin.x, (int)bounds.origin.y,
			   (int)bounds.size.width, (int)bounds.size.height);
	
	glOrtho(-1.0, 1.0, -1.0, 1.0, -10000.0, 10000.0);
	glMatrixMode(GL_MODELVIEW);
	
}

-(void)prepareOpenGL{
	
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();{
		glLoadIdentity();
		glRotatef(30, 1.0, -1.0, 0.0);
		glGetFloatv(GL_MODELVIEW,m);
	}glPopMatrix();
	
	//glMatrixMode(GL_MODELVIEW);
	//glLoadIdentity();
		
	glMaterialfv(GL_FRONT, GL_AMBIENT, materialAmbient);
	glMaterialfv(GL_FRONT, GL_DIFFUSE, materialDiffuse);
	glMaterialfv(GL_FRONT, GL_SPECULAR, materialSpecular);
	glMaterialfv(GL_FRONT, GL_SHININESS, materialShininess);
	
	const float emission[] = {0.1,0.1,0.1,1.0};
	glMaterialfv(GL_FRONT, GL_EMISSION, emission);
	
	glLightfv(GL_LIGHT0, GL_AMBIENT, light0Ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light0Diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light0Specular);
	glEnable(GL_LIGHT0);
	
	
	[self compileSpectrumsToDisplayList];
}



-(void)drawAxis{
	[[NSColor blueColor] openGLColor4f];
	glBegin(GL_LINES);{
		glVertex3d(-1.0, 0, 0);
		glVertex3d(1.0, 0, 0);
		
		glVertex3d(0.0, -1.0, 0);
		glVertex3d(0.0, 1.0, 0);

		glVertex3d(0, 0, -1.0);
		glVertex3d(0, 0, 1.0);

	}glEnd();
	
	drawGLString(1.0, 0 ,0 , "time");
	drawGLString(0, 1.0, 0,  "dB");
	drawGLString(0, 0, -1.0, "freq");
}

-(void)drawSamplePlanes{
	
	//don't draw back side
	//glEnable(GL_CULL_FACE);
	//glCullFace(GL_BACK);
	
	glEnable(GL_NORMALIZE);	//法線ベクトルの自動正規化
	
	//[[NSColor orangeColor] openGLColor4f];
	
	glBegin(GL_TRIANGLES);{

		float vertexes[2][3][3] = {
			{
				{-0.6, -0.3, 0.0},
				{0.6, -0.3, 0.0},
				{0.6, 0.3, 0.0}
			},
			{
				{-0.6, -0.3, 0.0},
				{0.6, 0.3, 0.0},
				{-0.6, 0.3, -0.6}
			}
		};
		GLfloat norm[3];
		
		norm_from_triangle(vertexes[0][0], vertexes[0][1] , vertexes[0][2],norm);			
		glNormal3fv(norm);
		glVertex3fv(vertexes[0][0]);
		glVertex3fv(vertexes[0][1]);
		glVertex3fv(vertexes[0][2]);
			
		norm_from_triangle(vertexes[1][0], vertexes[1][1] , vertexes[1][2],norm);			
		glNormal3fv(norm);
		glVertex3fv(vertexes[1][0]);
		glVertex3fv(vertexes[1][1]);
		glVertex3fv(vertexes[1][2]);
   }glEnd();
	
	glDisable(GL_NORMALIZE);
}

-(void)calculateSpectrums{
	_spectrums.clear();
	
	for (int i = 0 ; i < SPECTRUM3D_COUNT; i++){
		_spectrums.push_back(Spectrum(FFT_SIZE, 0.0));
	}
	
	RangeX *selection = [_aiff selection];
	float start = selection.start / 100.0f;
	float width = selection.end / 100.0f - start;
	float rate = width / SPECTRUM3D_COUNT;
	for (int i = 0; i < SPECTRUM3D_COUNT; i++){
		UInt32 frame = (UInt32)([_aiff totalFrameCount] * (start + i*rate));
		[_aiff fastFFTForFrame:frame toBuffer:_spectrums[i] size:FFT_SIZE];
	}

}

-(void)XYZFromSpectrum:(const Spectrum &)spectrum
			spec_index:(int) spec_index
			freq_index:(int) freq_index
					x:(float *)pX 
					 y:(float *)pY 
					z:(float *)pZ{
	float amp = abs(spectrum[freq_index])/spectrum.size();
	float db = 20 * std::log10(amp);
	if( db < -96.0) db = -96.0f;	//cutoff low values
	
	*pX/*time*/ = spec_index * 1.0 / _spectrums.size();
	*pY/*value*/ = (db + 96.0) * 1.0/96.0;	//1 for 96db
	*pZ/*freq*/ = freq_index * 1.0/(FFT_SIZE/2); 
	
	//tweaking
	//time
	*pX -= 0.5;	//centerize
	*pX *= 1.9;	//scale
	
	//amp //visible tweak
	*pY *= 0.5;
	
	//
	*pZ *= -1.0;	//z- axis is upside-down for openGL
	*pZ += 0.5;	//centerize;
	*pZ *= 1.5;	//scale	
}

-(void)drawSpectrumMesh{
	if (!_enabled) return;

	//make vertex arrays
	SimpleVertex3 points[_spectrums.size()][FFT_SIZE/2];
	for (int sindex = 0; sindex < _spectrums.size(); sindex++){
		for (int findex = 0; findex < FFT_SIZE/2; findex++){
			[self XYZFromSpectrum:_spectrums[sindex]
					   spec_index:sindex 
					   freq_index:findex 
								x:&(points[sindex][findex].x) 
								y:&(points[sindex][findex].y) 
								z:&(points[sindex][findex].z) ];
		}
	}
	
	//glShadeModel(GL_FLAT);
	glEnable(GL_NORMALIZE);
	for (int sindex = 0; sindex < _spectrums.size()-1; sindex++){
		glBegin(GL_TRIANGLES);		//want use GL_TRIANGLE_STRIP..
		
		for(int findex = 0; findex < FFT_SIZE/2-1; findex++){
			int s = sindex;
			int f = findex;
			
			GLfloat norm[3];
			GLfloat v1[3] = {points[s][f].x, points[s][f].y, points[s][f].z};
			GLfloat v2[3] = {points[s+1][f].x, points[s+1][f].y, points[s+1][f].z};
			GLfloat v3[3] = {points[s][f+1].x, points[s][f+1].y, points[s][f+1].z};
			norm_from_triangle(v1,v2,v3,norm);
			glNormal3fv(norm);
			glVertex3fv(v1);
			glVertex3fv(v2);
			glVertex3fv(v3);
			
			GLfloat v4[3] = {points[s][f+1].x, points[s][f+1].y, points[s][f+1].z};
			GLfloat v5[3] = {points[s+1][f].x, points[s+1][f].y, points[s+1][f].z};
			GLfloat v6[3] = {points[s+1][f+1].x, points[s+1][f+1].y, points[s+1][f+1].z};
			norm_from_triangle(v4,v5,v6,norm);
			glNormal3fv(norm);
			glVertex3fv(v4);
			glVertex3fv(v5);
			glVertex3fv(v6);
			
		}
		glEnd();
	}
	glDisable(GL_NORMALIZE);
	
}

-(void)drawSpectrums{
	if (!_enabled) return;
	
	[self calculateSpectrums];
	
	for (int spectrum_index = 0; spectrum_index < _spectrums.size(); spectrum_index++){
		Spectrum &spectrum = _spectrums[spectrum_index];
		glColor3f(spectrum_index*(0.9/_spectrums.size()), spectrum_index*(0.9/_spectrums.size()), 0.7);
		int length = FFT_SIZE/2;
		glBegin(GL_LINE_STRIP);
		for (int freq_index = 0; freq_index < length; freq_index++){
			float amp = abs(spectrum[freq_index])/spectrum.size();
			float db = 20 * std::log10(amp);
			if( db < -96.0) db = -96.0f;	//cutoff low values
			
			float x/*time*/ = spectrum_index * 1.0 / _spectrums.size();
			float y/*value*/ = (db + 96.0) * 1.0/96.0;	//1 for 96db
			float z/*freq*/ = freq_index * 1.0/length; 
			
			//tweaking
			//time
			x -= 0.5;	//centerize
			x *= 1.9;	//scale
			
			//amp //visible tweak
			y *= 0.5;
			
			//
			z *= -1.0;	//z- axis is upside-down for openGL
			z += 0.5;	//centerize;
			z *= 1.5;	//scale
			
			glVertex3d(x,y,z);
			
			//TODO log enabled case.
		}
		glEnd();
	}
	NSLog(@"Spectrum drawed");
}

-(void)compileSpectrumsToDisplayList{
	static bool firstCall = true;
	if (firstCall){
		firstCall = false;
	}else{
		glDeleteLists(displayList_Spectrum,1);
	}
	
	
	glNewList(displayList_Spectrum, GL_COMPILE);{
		
		[self drawSpectrums];
		//[self drawSpectrumMesh];
	}glEndList();
	
}


-(void)drawRect:(NSRect)dirtyRect{
	
	[[NSColor blackColor] openGLClearColor];
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glEnable(GL_DEPTH_TEST);
	glMatrixMode(GL_MODELVIEW);
	
	glPushMatrix();{
		glLightfv(GL_LIGHT0, GL_POSITION, light0Position);	//fixed light //seemds needs more light
		if (_rotateByTrackball){
			glTranslatef(0.0, 0.0, 0.0);//more tweak should go here
			glRotatef(_trackballRotation[0], _trackballRotation[1], _trackballRotation[2], _trackballRotation[3]);
			glRotatef(_worldRotation[0], _worldRotation[1], _worldRotation[2], _worldRotation[3]);
			
		}else{
			glMultMatrixf(m);
		}
		
		//glLightfv(GL_LIGHT1, GL_POSITION, light0Position);
		GLwithLight(^(void){
			const GLfloat materialCol[] = {0.2,0.2,0.5,1};
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, materialCol);
			//[self drawSamplePlanes];
			glPushMatrix();{
				glTranslated(0,0.4,-0.4);
				glutSolidTeapot(0.1);
			}glPopMatrix();
			
			const GLfloat materialCol2[] = {0.7,0.3,0.0,1};
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, materialCol2);
			[self drawSpectrumMesh];
		
		});
		//glCallList(displayList_Spectrum);
		[self drawAxis];
		

	}glPopMatrix();
	
	glDisable(GL_DEPTH_TEST);
	glFinish();
	glFlush();
}

#pragma mark ---- Mouse Handlings ----

- (NSPoint)locationFromEvent:(NSEvent *)theEvent{
	return [self convertPoint:[theEvent locationInWindow] fromView:nil];
}

- (void)mouseDown:(NSEvent *)theEvent{

	if (_rotateByTrackball){
		NSPoint location = [self locationFromEvent:theEvent];
		startTrackball(location.x, location.y, 0,0,self.bounds.size.width,self.bounds.size.height);
	}else{
		_mouseDragging = true;
		_prevDragPoint = [self locationFromEvent:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent{
	
	if (_rotateByTrackball){
		NSPoint location = [self locationFromEvent:theEvent];
		rollToTrackball(location.x, location.y, _trackballRotation);
		[self setNeedsDisplay:YES];
	}else{
		NSPoint curPoint = [self locationFromEvent:theEvent];
		
		if (_mouseDragging == false) return;
		
		float distanceX = curPoint.x -  _prevDragPoint.x;
		float distanceY = curPoint.y -  _prevDragPoint.y;
		float angleX = distanceX / self.bounds.size.width * 180;
		float angleY = distanceY / self.bounds.size.height * 180;
		
		//NSLog(@"drag(%f,%f) distance = %f", curPoint.x, curPoint.y, distanceX);
		[self addRotateY:angleX];
		[self addRotateX:-angleY];
		//[self rotate:3.0f forX:-angleY forY:angleX forZ:0];
		_prevDragPoint = curPoint;
	}
}

- (void)mouseUp:(NSEvent *)theEvent{
	NSLog(@"mouse up");
	if (_rotateByTrackball){
		addToRotationTrackball( _trackballRotation, _worldRotation);
		for (int i = 0 ; i < 4; i++){
			_trackballRotation[i] = 0.0f;
		}
		NSLog(@"current rotation = (%lf,%lf,%lf,%lf)", _worldRotation[0], _worldRotation[1], _worldRotation[2], _worldRotation[3]);
	}else{
		_mouseDragging = false;
	}
}



/*needs setAcceptsMouseMovedEvents for window, to receive this event*/
- (void)mouseMoved:(NSEvent *)theEvent{
	//needs setAcceptsMouseMovedEvents:
	NSLog(@"mouse moved");
}

- (void)rightMouseDown:(NSEvent *)theEvent{
	if (_rotateByTrackball){
		
	}else{
		_mouseDragging = true;
		_prevDragPoint = [self locationFromEvent:theEvent];
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	if (_rotateByTrackball){
		
	}else{
		NSPoint curPoint = [self locationFromEvent:theEvent];
		
		if (_mouseDragging == false) return;
		
		float distanceX = curPoint.x -  _prevDragPoint.x;
		float angleX = distanceX / self.bounds.size.width * 180;
		
		[self addRotateZ:angleX];
		distanceX /= self.bounds.size.width;
		//[self addShiftX:distanceX];
		_prevDragPoint = curPoint;
	}
}

-(void)rightMouseUp:(NSEvent *)theEvent{
	if (_rotateByTrackball){
		
	}else{
		_mouseDragging = false;
	}
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	//NSLog(@"other");
	//[self mouseDragged: theEvent];
}


#pragma mark ---- Setter with redraw ----
- (void)setRotateByTrackball:(Boolean)rotateByTrackball{
	_rotateByTrackball = rotateByTrackball;
	[self setNeedsDisplay:YES];
}

- (void)setLog:(Boolean)log{
	_log = log;
	[self setNeedsDisplay:YES];
}
- (void)setEnabled:(Boolean)enabled{
	_enabled = enabled;
	[self setNeedsDisplay:YES];
}


@end
