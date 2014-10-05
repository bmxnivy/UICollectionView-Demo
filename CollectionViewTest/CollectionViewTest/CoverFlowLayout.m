//
//  CoverFlowLayout.m
//  CollectionViewTest
//
//  Created by Mykola Vyshynskyi on 10/5/14.
//  Copyright (c) 2014 Jeremias Nunez. All rights reserved.
//

#import "CoverFlowLayout.h"

@interface CoverFlowLayout ()

- (UIEdgeInsets)sectionInsetsForCurrentInterfaceOrientation;

@end

@implementation CoverFlowLayout

- (id)init {
    self = [super init];
    
    if (self) {
        
        self.itemSize = CGSizeMake(400.0f, 600.0f);
        self.minAlpha = 0.25f;
        self.minScale = 0.9f;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 50.0f;
        
    }
    
    return self;

}

#pragma mark - Private methods
- (UIEdgeInsets)sectionInsetsForCurrentInterfaceOrientation
{
    CGFloat vInset = floorf(self.collectionView.frame.size.height/2.0f - self.itemSize.height/2.0f);
    CGFloat hInset = floorf(self.collectionView.frame.size.width/2.0f - self.itemSize.width/2.0f);

    return UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
}

#pragma mark - UICollectionViewLayout methods
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
    // update the layout (redraw) when we scroll throught it, we do this so we can zoom in on the center element
    // we also update the section inset here (it's bigger for portrait) so we always have ONE row, maintaining the "line" layout
    self.sectionInset = [self sectionInsetsForCurrentInterfaceOrientation];
    
    return YES;
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* attribsArray = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect = CGRectZero;
    
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    for (UICollectionViewLayoutAttributes* attributes in attribsArray) {
        // we'll apply a small zoom to the items that are on the visible area
        if (CGRectIntersectsRect(attributes.frame, visibleRect)) {
            // do some weird math
            CGFloat distance = CGRectGetMidX(visibleRect) - attributes.center.x;
            
            if (ABS(distance) < visibleRect.size.width) {
                CGFloat normalizedDistance = ABS(distance) / visibleRect.size.width;
                CGFloat pageScale = 1 - normalizedDistance * (1 - _minScale);
                
                attributes.alpha = 1 - (ABS(distance) / attributes.frame.size.width) * (1 - _minAlpha);
                attributes.transform3D = CATransform3DMakeScale(pageScale, pageScale, 1.0f);
                // put on top
                attributes.zIndex = 1;
            } else {
                attributes.alpha = _minAlpha;
                attributes.transform3D = CATransform3DMakeScale(_minScale, _minScale, 1.0f);
            }
        }
    }
    
    return attribsArray;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    // adjust the offset so that when we finish scrolling, the target cell is centered in the scroll properly
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0f);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0f, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
    NSArray* attribsArray = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes* layoutAttributes in attribsArray) {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}

#pragma mark - Setter methods
- (void)setMinScale:(CGFloat)minScale
{
    if (_minScale == minScale) {
        return;
    }
    
    _minScale = minScale;
    [self invalidateLayout];
}

- (void)setMinAlpha:(CGFloat)minAlpha
{
    if (_minAlpha == minAlpha) {
        return;
    }
    
    _minAlpha = minAlpha;
    [self invalidateLayout];
}

@end
