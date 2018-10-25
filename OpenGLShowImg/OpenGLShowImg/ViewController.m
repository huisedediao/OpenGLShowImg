//
//  ViewController.m
//  OpenGLShowImg
//
//  Created by xxb on 2018/10/25.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView_img.h"

@interface ViewController ()
@property (nonatomic,strong) OpenGLView_img *glView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 200, 20)];
    [self.view addSubview:tipLabel];
    tipLabel.text = @"点击屏幕展示图片";
    
    NSString* pngFilePath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
    self.glView = [[OpenGLView_img alloc] initWithFrame:self.view.bounds filePath:pngFilePath];
    [self.view addSubview:self.glView];
    self.glView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.glView render];
}

- (void) dealloc
{
    if(self.glView){
        [self.glView destroy];
        self.glView = nil;
    }
}


@end
