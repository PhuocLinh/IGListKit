/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <IGListKit/IGListCollectionViewLayout.h>

#import "IGListCollectionViewLayoutInternal.h"
#import "IGLayoutTestDataSource.h"
#import "IGLayoutTestItem.h"
#import "IGLayoutTestSection.h"

@interface IGListCollectionViewLayoutTests : XCTestCase

@property (nonatomic, strong) IGListCollectionViewLayout *layout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) IGLayoutTestDataSource *dataSource;

@end

static const CGRect kTestFrame = (CGRect){{0, 0}, {100, 100}};

static NSIndexPath *quickPath(NSInteger section, NSInteger item) {
    return [NSIndexPath indexPathForItem:item inSection:section];
}

#define IGAssertEqualFrame(frame, x, y, w, h, ...) \
do { \
CGRect expected = CGRectMake(x, y, w, h); \
XCTAssertEqual(CGRectGetMinX(expected), CGRectGetMinX(frame)); \
XCTAssertEqual(CGRectGetMinY(expected), CGRectGetMinY(frame)); \
XCTAssertEqual(CGRectGetWidth(expected), CGRectGetWidth(frame)); \
XCTAssertEqual(CGRectGetHeight(expected), CGRectGetHeight(frame)); \
} while(0)

@implementation IGListCollectionViewLayoutTests

- (UICollectionViewCell *)cellForSection:(NSInteger)section item:(NSInteger)item {
    return [self.collectionView cellForItemAtIndexPath:quickPath(section, item)];
}

- (UICollectionReusableView *)headerForSection:(NSInteger)section {
    return [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:quickPath(section, 0)];
}

- (void)setUpWithStickyHeaders:(BOOL)sticky topInset:(CGFloat)inset {
    [self setUpWithStickyHeaders:sticky topInset:inset stretchToEdge:NO];
}

- (void)setUpWithStickyHeaders:(BOOL)sticky topInset:(CGFloat)inset stretchToEdge:(BOOL)stretchToEdge {
    self.layout = [[IGListCollectionViewLayout alloc] initWithStickyHeaders:sticky topContentInset:inset stretchToEdge:stretchToEdge];
    self.dataSource = [IGLayoutTestDataSource new];
    self.collectionView = [[UICollectionView alloc] initWithFrame:kTestFrame collectionViewLayout:self.layout];
    self.collectionView.dataSource = self.dataSource;
    self.collectionView.delegate = self.dataSource;
    [self.dataSource configCollectionView:self.collectionView];
}

- (void)tearDown {
    [super tearDown];

    self.collectionView = nil;
    self.layout = nil;
    self.dataSource = nil;
}

- (void)prepareWithData:(NSArray<IGLayoutTestSection *> *)data {
    self.dataSource.sections = data;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
}

- (void)test_whenEmptyData_thatContentSizeZero {
    [self setUpWithStickyHeaders:YES topInset:0];

    [self prepareWithData:nil];

    // check so that nil messaging doesn't default size to 0
    XCTAssertEqual(self.layout.collectionView, self.collectionView);
    XCTAssertTrue(CGSizeEqualToSize(CGSizeZero, self.collectionView.contentSize));
}

- (void)test_whenLayingOutCells_withHeaderHeight_withLineSpacing_withInsets_thatFramesCorrect {
    [self setUpWithStickyHeaders:NO topInset:0];

    const CGFloat headerHeight = 10;
    const CGFloat lineSpacing = 10;
    const UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 5, 5);

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,10}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,20}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,30}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 120);
    IGAssertEqualFrame([self headerForSection:0].frame, 10, 10, 85, 10);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 10, 20, 85, 10);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 10, 40, 85, 20);
    IGAssertEqualFrame([self headerForSection:1].frame, 10, 75, 85, 10);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 10, 85, 85, 30);
}

- (void)test_whenUsingStickyHeaders_withSimulatedScrolling_thatYPositionsAdjusted {
    [self setUpWithStickyHeaders:YES topInset:10];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,20}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,20}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,30}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,30}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,30}],
                                                                          ]],
                            ]];

    // scroll header 0 halfway
    self.collectionView.contentOffset = CGPointMake(0, 5);
    [self.collectionView layoutIfNeeded];
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 15, 100, 10);
    IGAssertEqualFrame([self headerForSection:1].frame, 0, 50, 100, 10);

    // scroll header 0 off and 1 up
    self.collectionView.contentOffset = CGPointMake(0, 45);
    [self.collectionView layoutIfNeeded];
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 40, 100, 10);
    IGAssertEqualFrame([self headerForSection:1].frame, 0, 55, 100, 10);
}

- (void)test_whenAdjustingTopYInset_withVaryingHeaderHeights_thatYPositionsUpdated {
    [self setUpWithStickyHeaders:YES topInset:10];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,10}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,20}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,30}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,40}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){100,50}],
                                                                          ]],
                            ]];

    // scroll header 0 off and 1 up
    self.collectionView.contentOffset = CGPointMake(0, 35);
    [self.collectionView layoutIfNeeded];
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 30, 100, 10);
    IGAssertEqualFrame([self headerForSection:1].frame, 0, 45, 100, 10);

    self.layout.stickyHeaderOriginYAdjustment = -10;
    [self.collectionView layoutIfNeeded];
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 30, 100, 10);
    IGAssertEqualFrame([self headerForSection:1].frame, 0, 40, 100, 10);

    self.layout.stickyHeaderOriginYAdjustment = 10;
    [self.collectionView layoutIfNeeded];
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 30, 100, 10);
    IGAssertEqualFrame([self headerForSection:1].frame, 0, 55, 100, 10);
}

- (void)test_whenItemsSmallerThanContainerWidth_with0Insets_with0LineSpacing_with0Interitem_thatItemsFitSameRow {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 66);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 33, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:0 item:2].frame, 66, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 0, 33, 33, 33);
}

- (void)test_whenItemsSmallerThanContainerWidth_withHalfPointItemSpacing_with0Insets_with0LineSpacing_thatItemsFitSameRow {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0.5
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 33);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    const CGRect rect = IGListRectIntegralScaled(CGRectMake(33.5, 0, 33, 33));
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    IGAssertEqualFrame([self cellForSection:0 item:2].frame, 67, 0, 33, 33);
}

- (void)test_whenSectionsSmallerThanContainerWidth_with0ItemSpacing_with0Insets_with0LineSpacing_thatSectionsFitSameRow {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 33);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 33, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 66, 0, 33, 33);
}

- (void)test_whenSectionsSmallerThanContainerWidth_withHalfPointSpacing_with0Insets_with0LineSpacing_thatSectionsFitSameRow {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0.5
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0.5
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0.5
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 33);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    const CGRect rect = IGListRectIntegralScaled(CGRectMake(33.5, 0, 33, 33));
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 67, 0, 33, 33);
}

- (void)test_whenSectionsSmallerThanContainerWidth_with0ItemSpacing_withMiddleItemHasInsets_with0LineSpacing_thatNextSectionSnapsBelow {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){13,50}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 103);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 43, 10, 13, 50);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 66, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:3 item:0].frame, 0, 70, 33, 33);
}

- (void)test_whenSectionBustingRow_thatNewlineAppliesSectionInset {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsMake(10, 10, 5, 5)
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,50}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 98);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 10, 43, 85, 50);
}

- (void)test_whenSectionsSmallerThanWidth_withSectionHeader_thatHeaderCausesNewline {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 76);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 0, 43, 33, 33);
}

- (void)test_whenBatchItemUpdates_withHeaderHeight_withLineSpacing_withInsets_thatLayoutCorrectAfterUpdates {
    [self setUpWithStickyHeaders:NO topInset:0];

    const CGFloat headerHeight = 10;
    const CGFloat lineSpacing = 10;
    const UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 5, 5);

    // making the view bigger so that we can check all cell frames
    self.collectionView.frame = CGRectMake(0, 0, 100, 400);

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,10}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,20}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,30}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,60}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:insets
                                                            lineSpacing:lineSpacing
                                                       interitemSpacing:0
                                                           headerHeight:headerHeight
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,40}],
                                                                          ]],
                            ]];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.collectionView performBatchUpdates:^{
        self.dataSource.sections = @[
                                     [[IGLayoutTestSection alloc] initWithInsets:insets
                                                                     lineSpacing:lineSpacing
                                                                interitemSpacing:0
                                                                    headerHeight:headerHeight
                                                                           items:@[
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,30}], // reloaded
                                                                                   // deleted
                                                                                   ]],
                                     // moved from section 3 to 1
                                     [[IGLayoutTestSection alloc] initWithInsets:insets
                                                                     lineSpacing:lineSpacing
                                                                interitemSpacing:0
                                                                    headerHeight:headerHeight
                                                                           items:@[
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,40}],
                                                                                   ]],
                                     // deleted section 2
                                     [[IGLayoutTestSection alloc] initWithInsets:insets
                                                                     lineSpacing:lineSpacing
                                                                interitemSpacing:0
                                                                    headerHeight:headerHeight
                                                                           items:@[
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,30}],
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,10}], // inserted
                                                                                   ]],
                                     // inserted
                                     [[IGLayoutTestSection alloc] initWithInsets:insets
                                                                     lineSpacing:lineSpacing
                                                                interitemSpacing:0
                                                                    headerHeight:headerHeight
                                                                           items:@[
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,10}],
                                                                                   [[IGLayoutTestItem alloc] initWithSize:(CGSize){85,20}],
                                                                                   ]],
                                     ];

        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:2]];
        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:3]];
        [self.collectionView moveSection:3 toSection:1];
        [self.collectionView reloadItemsAtIndexPaths:@[quickPath(0, 0)]];
        [self.collectionView deleteItemsAtIndexPaths:@[quickPath(0, 1)]];
        [self.collectionView insertItemsAtIndexPaths:@[quickPath(2, 1)]];
    } completion:^(BOOL finished) {
        [self.collectionView layoutIfNeeded];
        [expectation fulfill];

        XCTAssertEqual(self.collectionView.contentSize.height, 260);

        IGAssertEqualFrame([self headerForSection:0].frame, 10, 10, 85, 10);
        IGAssertEqualFrame([self cellForSection:0 item:0].frame, 10, 20, 85, 30);
        
        IGAssertEqualFrame([self headerForSection:1].frame, 10, 65, 85, 10);
        IGAssertEqualFrame([self cellForSection:1 item:0].frame, 10, 75, 85, 40);
        
        IGAssertEqualFrame([self headerForSection:2].frame, 10, 130, 85, 10);
        IGAssertEqualFrame([self cellForSection:2 item:0].frame, 10, 140, 85, 30);
        IGAssertEqualFrame([self cellForSection:2 item:1].frame, 10, 180, 85, 10);
        
        IGAssertEqualFrame([self headerForSection:3].frame, 10, 205, 85, 10);
        IGAssertEqualFrame([self cellForSection:3 item:0].frame, 10, 215, 85, 10);
        IGAssertEqualFrame([self cellForSection:3 item:1].frame, 10, 235, 85, 20);
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)test_whenQueryingLayoutAttributes_withLotsOfCells_thatExactFramesFetched {
    [self setUpWithStickyHeaders:NO topInset:0];

    NSMutableArray *items = [NSMutableArray new];
    for (NSInteger i = 0; i < 1000; i++) {
        [items addObject:[[IGLayoutTestItem alloc] initWithSize:(CGSize){100,20}]];
    }

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:items]
                            ]];

    XCTAssertEqual([self.layout layoutAttributesForElementsInRect:CGRectMake(0, 500, 100, 100)].count, 5);
    XCTAssertEqual([self.layout layoutAttributesForElementsInRect:CGRectMake(0, 0, 100, 1000)].count, 50);
    XCTAssertEqual([self.layout layoutAttributesForElementsInRect:CGRectMake(0, 250, 100, 100)].count, 6);
    XCTAssertEqual([self.layout layoutAttributesForElementsInRect:CGRectMake(0, 250, 100, 1)].count, 1);
}

- (void)test_whenChangingBoundsSize_withItemsThatNewlineAfterChange_thatLayoutShiftsItems {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){33,33}],
                                                                          ]],
                            ]];

    XCTAssertEqual(self.collectionView.contentSize.height, 33);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 33, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 66, 0, 33, 33);

    // can no longer fit 3 items in one section
    self.collectionView.frame = CGRectMake(0, 0, 70, 100);
    [self.collectionView layoutIfNeeded];

    XCTAssertEqual(self.collectionView.contentSize.height, 66);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 33, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 0, 33, 33, 33);
}

- (void)test_whenCollectionViewContentInset_withFullWidthItems_thatItemsPinchedIn {
    [self setUpWithStickyHeaders:NO topInset:0];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 30, 0, 30);

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:10
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){40,10}],
                                                                          [[IGLayoutTestItem alloc] initWithSize:(CGSize){40,20}],
                                                                          ]],
                            ]];
    XCTAssertEqual(self.collectionView.contentSize.height, 40);
    IGAssertEqualFrame([self headerForSection:0].frame, 0, 0, 40, 10);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 10, 40, 10);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 0, 20, 40, 20);
}

- (void)test_whenItemsAddedWidthSmallerThanWidth_DifferenceSmallerThanEpsilon {
    [self setUpWithStickyHeaders:NO topInset:0 stretchToEdge:YES];

    const CGSize size = CGSizeMake(33, 33);
    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:size],
                                                                          [[IGLayoutTestItem alloc] initWithSize:size],
                                                                          [[IGLayoutTestItem alloc] initWithSize:size],
                                                                          ]],
                            ]];
    
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 33, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:0 item:2].frame, 66, 0, 34, 33);
}

- (void)test_whenItemsAddedWidthSmallerThanWidth_DifferenceBiggerThanEpsilon {
    [self setUpWithStickyHeaders:NO topInset:0 stretchToEdge:YES];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(33, 33)],
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(65, 33)],
                                                                          ]],
                            ]];
    
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 33, 33);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 33, 0, 65, 33);
}

- (void)test_whenItemsAddedWithBiggerThanWidth_DifferenceSmallerThanEpsilon {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(50, 50)],
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(51, 50)],
                                                                          ]],
                            ]];
    
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 50, 50);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 50, 0, 51, 50);
}

- (void)test_whenItemsAddedWithBiggerThanWidth_DifferenceBiggerThanEpsilon {
    [self setUpWithStickyHeaders:NO topInset:0];

    [self prepareWithData:@[
                            [[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsZero
                                                            lineSpacing:0
                                                       interitemSpacing:0
                                                           headerHeight:0
                                                                  items:@[
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(50, 50)],
                                                                          [[IGLayoutTestItem alloc] initWithSize:CGSizeMake(52, 50)],
                                                                          ]],
                            ]];
    
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 0, 0, 50, 50);
    IGAssertEqualFrame([self cellForSection:0 item:1].frame, 0, 50, 52, 50);
}

- (void)test_ {
    [self setUpWithStickyHeaders:NO topInset:0];
    self.collectionView.frame = CGRectMake(0, 0, 414, 736);
    
    NSMutableArray *data = [NSMutableArray new];
    for (NSInteger i = 0; i < 6; i++) {
        [data addObject:[[IGLayoutTestSection alloc] initWithInsets:UIEdgeInsetsMake(1, 1, 1, 1)
                                                        lineSpacing:0
                                                   interitemSpacing:0
                                                       headerHeight:0
                                                              items:@[
                                                                      [[IGLayoutTestItem alloc] initWithSize:(CGSize){136, 136}],
                                                                      ]]];
    }
    [self prepareWithData:data];
    
    XCTAssertEqual(self.collectionView.contentSize.height, 276);
    IGAssertEqualFrame([self cellForSection:0 item:0].frame, 1, 1, 136, 136);
    IGAssertEqualFrame([self cellForSection:1 item:0].frame, 139, 1, 136, 136);
    IGAssertEqualFrame([self cellForSection:2 item:0].frame, 277, 1, 136, 136);
    IGAssertEqualFrame([self cellForSection:3 item:0].frame, 1, 139, 136, 136);
    IGAssertEqualFrame([self cellForSection:4 item:0].frame, 139, 139, 136, 136);
    IGAssertEqualFrame([self cellForSection:5 item:0].frame, 277, 139, 136, 136);
}

@end
