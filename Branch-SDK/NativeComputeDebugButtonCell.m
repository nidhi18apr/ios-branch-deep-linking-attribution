//
//  NativeComputeDebugButtonCell.m
//  Branch
//
//  Created by Usman Shafique on 8/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "NativeComputeDebugButtonCell.h"

@interface NativeComputeDebugButtonCell()
@property (nonatomic, weak) UIButton *processConfigButton;
@end

@implementation NativeComputeDebugButtonCell

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
    
    // textView config
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
    
    // button config
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setTitle:@"Process All Config URLs" forState:UIControlStateNormal];
    [button setBackgroundColor:UIColor.blackColor];
    [button setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setEnabled:YES];
    [button setUserInteractionEnabled:YES];
    [self.contentView addSubview:button];
    self.processConfigButton = button;
    [button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView setUserInteractionEnabled:YES];
    [self.contentView setMultipleTouchEnabled:YES];

    
    [NSLayoutConstraint activateConstraints:@[
       [self.textView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
       [self.textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
       [self.textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
       
       [self.processConfigButton.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor],
       [self.processConfigButton.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
       [self.processConfigButton.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
       [self.processConfigButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textView.text = nil;
}

- (void)didTapButton:(id)sender {
}


@end
