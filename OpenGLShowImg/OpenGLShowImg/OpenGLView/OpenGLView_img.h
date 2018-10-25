//
//  OpenGLView_img.h
//  OpenGLStudy
//
//  Created by xxb on 2018/10/24.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLView_img : UIView

- (id)initWithFrame:(CGRect)frame filePath:(NSString *)filePath;

- (void)render;

- (void) destroy;

@end

NS_ASSUME_NONNULL_END
