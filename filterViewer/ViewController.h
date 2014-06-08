//
//  ViewController.h
//  filterViewer
//
//  Created by earth on 6/8/14.
//  Copyright (c) 2014 filmhomage.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
<UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    UIScrollView*   _scrollView;
    UIImageView*    _imageView;
    
    UIToolbar*      _toolbar;
    
    UIImage*        _imageOriginal;
    UIImage*        _imagePreview;
    UIImage*        _imageResizeForFilter;
    
    BOOL            _bImagePickerShowOnce;
    int             _nSelectedFilterNumber;
}

@property(nonatomic, retain)UIScrollView* scrollView;
@property(nonatomic, retain)UIImageView* imageView;
@property(nonatomic, retain)UIImage* imagePreview;
@property(nonatomic, retain)UIImage* imageOriginal;
@property(nonatomic, retain)UIImage* imageResizeForFilter;
@property(nonatomic, retain)UIToolbar* toolbar;
@property (nonatomic,retain) NSDictionary* metadataDict;

@end
