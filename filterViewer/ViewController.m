//
//  ViewController.m
//  filterViewer
//
//  Created by earth on 6/8/14.
//  Copyright (c) 2014 filmhomage.net. All rights reserved.
//

#import "ViewController.h"
#import "Utilites.h"
#import "Contants.h"
#import <CoreImage/CoreImage.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define kSaveToolbarTag     0x80000000
#define kIndicatorViewTag   0x90000000

@implementation ViewController

@synthesize scrollView = _scrollView;
@synthesize imageView = _imageView;
@synthesize imageOriginal = _imageOriginal;
@synthesize imagePreview = _imagePreview;
@synthesize imageResizeForFilter = _imageResizeForFilter;
@synthesize toolbar = _toolbar;
@synthesize metadataDict = _metadataDict;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc
{
    [super dealloc];
    
    self.scrollView = nil;
    self.imageView = nil;
    self.imageOriginal = nil;
    self.imagePreview = nil;
    self.metadataDict = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.view.backgroundColor = [UIColor blackColor];

    // Do any additional setup after loading the view, typically from a nib.
    UIBarButtonItem *flex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *save = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                           target:self
                                                                           action:@selector(save:)] autorelease];
    save.tag = kSaveToolbarTag;
    UIBarButtonItem *photoLibrary = [[[UIBarButtonItem alloc] initWithTitle:@"CameraRoll"
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(photoLibrary:)] autorelease];


    NSArray* itemsArray = @[photoLibrary, flex, save];

    self.toolbar = [[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 32)]autorelease];
    self.toolbar.barStyle = UIBarStyleDefault;
    [self.toolbar setItems:itemsArray];
    self.toolbar.tintColor = [UIColor blackColor];

    [self.view addSubview:self.toolbar];
    CGRect rectBounds = self.view.bounds;
    rectBounds = CGRectMake(rectBounds.origin.x,
                            self.toolbar.frame.origin.y + self.toolbar.frame.size.height,
                            rectBounds.size.width,
                            rectBounds.size.height - (self.toolbar.bounds.origin.y + self.toolbar.bounds.size.height) - self.scrollView.bounds.size.height - 100);

    self.imageView = [[[UIImageView alloc]initWithFrame:rectBounds]autorelease];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.imageView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(_bImagePickerShowOnce == NO)
    {
        UIImagePickerController* pickerController = [[UIImagePickerController alloc]init];
        pickerController.delegate = self;
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:pickerController animated:YES completion:nil];
        
        _bImagePickerShowOnce = YES;
    }
}

-(IBAction)save:(id)sender
{
    // Apply to filter Original Image
    {
        NSString* name = [NSString stringWithFormat:@"filter%.2ld:", (long)_nSelectedFilterNumber];
        SEL sel = NSSelectorFromString(name);
        if([self respondsToSelector:sel])
        {
            dispatch_queue_t q_main, q_thumbnail;
            q_main = dispatch_get_main_queue();
            q_thumbnail = dispatch_queue_create("cfview.create.artfilter", NULL);
            dispatch_async(q_thumbnail, ^
                           {
                               dispatch_async(q_main, ^
                                              {
                                                  UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
                                                  
                                                  indicator.tag = kIndicatorViewTag;
                                                  [self.view addSubview:indicator];
                                                  [indicator setCenter:CGPointMake(self.imageView.frame.size.width/2, self.imageView.frame.size.height/2)];
                                                  [indicator startAnimating];
                                              });
                               
                               UIImage* newImage = [self performSelector:sel withObject:self.imageOriginal];
                               
                               dispatch_async(q_main, ^
                                              {
                                                  if(newImage)
                                                  {
                                                      // Save Process
                                                      ALAssetsLibrary* assetLibrary = [[[ALAssetsLibrary alloc] init]autorelease];
                                                      [assetLibrary writeImageToSavedPhotosAlbum:[newImage CGImage] metadata:self.metadataDict completionBlock:^(NSURL* url, NSError* e)
                                                       {
                                                           UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@""
                                                                                                                message:@"Save Finish"
                                                                                                               delegate:self
                                                                                                      cancelButtonTitle:@"OK"
                                                                                                      otherButtonTitles:nil] autorelease];
                                                           [alertView show];
                                                       }];
                                                      
                                                      UIView* viewIndicator = [self.view viewWithTag:kIndicatorViewTag];
                                                      if(viewIndicator)
                                                      {
                                                          [viewIndicator removeFromSuperview];
                                                          viewIndicator = nil;
                                                      }
                                                      
                                                      [UIView beginAnimations:nil context:nil];
                                                      [UIView setAnimationDuration:0.5];
                                                      [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                                                      [UIView commitAnimations];
                                                  }
                                                  
                                                  
                                              });
                               dispatch_release(q_thumbnail);
                           });
        }
    }
}

-(IBAction)photoLibrary:(id)sender
{
    UIImagePickerController* pickerController = [[UIImagePickerController alloc]init];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)createFilterPreview
{
    UIScrollView* scrollViewFilter = [[[UIScrollView alloc]initWithFrame:CGRectMake(0,
                                                                                    self.view.bounds.size.height - 100,
                                                                                    320,
                                                                                    100)]autorelease];
    
    int nFilterCount = 8;
    CGFloat fWidth = 90;
    CGFloat fOffset = 10;
    
    scrollViewFilter.tag = VIEW_TAG_SCROLL_VIEW;
    scrollViewFilter.contentSize = CGSizeMake(nFilterCount * fWidth + fOffset, 100);
    
    for( int nCount = 0; nCount < nFilterCount ; nCount++)
    {
        UIButton* imageViewFilterPreview = [[[UIButton alloc]init]autorelease];
        CGRect rectPreviewFrame = CGRectMake(nCount * fWidth + fOffset, fOffset, fWidth - fOffset, fWidth- fOffset);
        imageViewFilterPreview.frame = rectPreviewFrame;
        imageViewFilterPreview.tag = VIEW_TAG_SCROLLVIEW_FILTER_PREVIEW + nCount;
        imageViewFilterPreview.contentMode = UIViewContentModeScaleAspectFit;
        
        [imageViewFilterPreview addTarget:self action:@selector(filterTapped:) forControlEvents:UIControlEventTouchUpInside];
        [scrollViewFilter addSubview:imageViewFilterPreview];
        
        NSString* name = [NSString stringWithFormat:@"filter%.2d:", nCount];
        SEL sel = NSSelectorFromString(name);
        if([self respondsToSelector:sel])
        {
            dispatch_queue_t q_main, q_thumbnail;
            q_main = dispatch_get_main_queue();
            q_thumbnail = dispatch_queue_create("cfview.create.filterPreview", NULL);
            
            dispatch_async(q_thumbnail, ^
                           {
                               dispatch_async(q_main, ^
                                              {
                                                  UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
                                                  indicator.tag = imageViewFilterPreview.tag;
                                                  [imageViewFilterPreview addSubview:indicator];
                                                  [indicator setCenter:CGPointMake(imageViewFilterPreview.frame.size.width/2,imageViewFilterPreview.frame.size.height/2)];
                                                  [indicator startAnimating];
                                                  
                                                  
                                              });
                               
                               UIImage* newImage = [self performSelector:sel withObject:self.imageResizeForFilter];
                               
                               dispatch_async(q_main, ^
                                              {
                                                  if(newImage)
                                                  {
                                                      [self removeButtonInFilter:imageViewFilterPreview];
                                                      
                                                      [imageViewFilterPreview setImage:newImage forState:UIControlStateNormal];
                                                      
                                                      [UIView beginAnimations:nil context:nil];
                                                      [UIView setAnimationDuration:0.5];
                                                      [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                                                      [UIView commitAnimations];
                                                  }
                                                  
                                                  
                                              });
                               dispatch_release(q_thumbnail);
                           });
        }
    }
    
    scrollViewFilter.backgroundColor = [UIColor clearColor];
    [self.view addSubview:scrollViewFilter];
}

-(IBAction)filterTapped:(UIButton*)sender
{
    if(sender)
    {
        _nSelectedFilterNumber = sender.tag;
        
        NSString* name = [NSString stringWithFormat:@"filter%.2ld:", (long)sender.tag];
        SEL sel = NSSelectorFromString(name);
        if([self respondsToSelector:sel])
        {
            dispatch_queue_t q_main, q_thumbnail;
            q_main = dispatch_get_main_queue();
            q_thumbnail = dispatch_queue_create("cfview.create.artfilter", NULL);
            dispatch_async(q_thumbnail, ^
                           {
                               dispatch_async(q_main, ^
                                              {
                                                  UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
                                                  indicator.tag = self.imageView.tag;
                                                  [self.imageView addSubview:indicator];
                                                  [indicator setCenter:CGPointMake(self.imageView.frame.size.width/2, self.imageView.frame.size.height/2)];
                                                  [indicator startAnimating];
                                              });
                               
                               self.imageView.image = nil;
                               UIImage* newImage = [self performSelector:sel withObject:self.imagePreview];
                               
                               dispatch_async(q_main, ^
                                              {
                                                  if(newImage)
                                                  {
                                                      [self removeImageView];
                                                      self.imageView.image = newImage;
                                                      [self.imageView setNeedsDisplay];
                                                      
                                                      [UIView beginAnimations:nil context:nil];
                                                      [UIView setAnimationDuration:0.5];
                                                      [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                                                      [UIView commitAnimations];
                                                  }
                                                  
                                                  
                                              });
                               dispatch_release(q_thumbnail);
                           });
        }
    }
}

//------------------------------------------------
#pragma mark
#pragma mark - View add / remove
//------------------------------------------------
-(void)removeButtonInFilter:(UIButton*)imageViewFilterPreview
{
    for(UIView* view in [imageViewFilterPreview subviews])
    {
        if([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            if(view.tag == imageViewFilterPreview.tag)
            {
                [view removeFromSuperview];
                break;
            }
        }
    }
}

-(void)removeImageView
{
    for(UIView* view in [self.imageView subviews])
    {
        if([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            if(view.tag == self.imageView.tag)
            {
                [view removeFromSuperview];
                break;
            }
        }
    }
}

-(void)removeFilterPreview
{
    UIView* view = [self.view viewWithTag:VIEW_TAG_SCROLL_VIEW];
    if(view)
    {
        for(UIView* viewSub in view.subviews)
        {
            [viewSub removeFromSuperview];
            viewSub = nil;
        }
        
        [view removeFromSuperview];
        view = nil;
    }
}

//------------------------------------------------
#pragma mark
#pragma mark - UIImagePickerController delegate
//------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.imageOriginal = nil;
    self.imagePreview = nil;
    self.imageView.image = nil;
    
    [self removeFilterPreview];
    
    __block ALAssetRepresentation* rep = nil;
    
    [picker dismissViewControllerAnimated:NO completion:^
     {
         NSURL* imageURL = info[UIImagePickerControllerReferenceURL];
         
         self.metadataDict = [rep metadata];
         
         [self photoFromALAssets:imageURL];
         
         self.imageOriginal = info[UIImagePickerControllerOriginalImage];
         self.imagePreview = [Utilites resizeImage:self.imageOriginal maxResolution:600];
         self.imageView.image = self.imagePreview;
         [self createFilterPreview];
     }];
    
    [picker release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [picker release];
}


-(void)photoFromALAssets:(NSURL*)imageurl
{
    ALAssetsLibrary* library = [[[ALAssetsLibrary alloc] init]autorelease];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0),
                   ^{
                       [library assetForURL:imageurl resultBlock: ^(ALAsset *asset)
                        {
                            if(asset)
                            {
                                self.imageResizeForFilter = [[[UIImage alloc] initWithCGImage:asset.thumbnail]autorelease];
                                
                            }
                        }
                               failureBlock:^(NSError *error)
                        {
                            NSLog(@"error:%@", error);
                        }];
                   });
}


//------------------------------------------------
#pragma mark
#pragma mark - filter preview
//------------------------------------------------
- (UIImage*)getFilterCGGimage:(CIFilter*)ciFilter imageOrientation:(UIImageOrientation)orientation
{
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [ciContext createCGImage:[ciFilter outputImage] fromRect:[[ciFilter outputImage] extent]];
    UIImage* resultFilteredImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
    CGImageRelease(cgimg);
    
    return resultFilteredImage;
}

- (UIImage*)filter03:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CISepiaTone"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputIntensity", @0.8f,
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter06:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorMonochrome"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputColor", [CIColor colorWithRed:0.75 green:0.75 blue:0.75],
                          @"inputIntensity", @1.0f,
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter02:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorInvert"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter00:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIFalseColor"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputColor0", [CIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                          @"inputColor1", [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1],
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter04:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorControls"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputSaturation", @1.0f,
                          @"inputBrightness", @0.5f,
                          @"inputContrast", @3.0f,
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter05:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIToneCurve"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputPoint0", [CIVector vectorWithX:0.0 Y:0.0],
                          @"inputPoint1", [CIVector vectorWithX:0.25 Y:0.1],
                          @"inputPoint2", [CIVector vectorWithX:0.5 Y:0.5],
                          @"inputPoint3", [CIVector vectorWithX:0.75 Y:0.9],
                          @"inputPoint4", [CIVector vectorWithX:1 Y:1],
                          nil];
    
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter01:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIHueAdjust"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputAngle",@3.14f,
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

- (UIImage*)filter07:(UIImage*)image
{
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIDotScreen"
                                    keysAndValues:kCIInputImageKey,
                          [[[CIImage alloc] initWithCGImage:image.CGImage]autorelease],
                          @"inputWidth",@25.00f,
                          @"inputAngle",@0.00f,
                          @"inputSharpness",@0.70f,
                          nil];
    
    return [self getFilterCGGimage:ciFilter imageOrientation:image.imageOrientation];
}

@end