//
//  NativeComputeDebugCell.m
//  Branch
//
//  Created by Usman Shafique on 8/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "NativeComputeDebugCell.h"

@interface NativeComputeDebugCell()
@end

@implementation NativeComputeDebugCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self initialize];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self initialize];
    return self;
}

- (void)initialize {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero];
    [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [textView setEditable:NO];
    [textView setScrollEnabled:NO];
    [textView setEditable:NO];
    [textView setTextAlignment:NSTextAlignmentLeft];
    [textView setBackgroundColor:UIColor.lightGrayColor];
    [textView setTextColor:UIColor.blackColor];
    [self.contentView addSubview:textView];
    self.textView = textView;
    
    
    [NSLayoutConstraint activateConstraints:@[
       [self.textView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
       [self.textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
       [self.textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
       [self.textView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textView.text = nil;
}


@end
