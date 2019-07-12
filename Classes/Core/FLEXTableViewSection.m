//
//  FLEXTableViewSection.m
//  FLEX
//
//  Created by Tanner Bennett on 7/11/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableViewSection.h"

@implementation FLEXTableViewSection

+ (instancetype)section:(NSInteger)section title:(NSString *)title rows:(NSArray *)rows {
    FLEXTableViewSection *s = [self new];
    s->_section = section;
    s->_title = title;
    s->_rows = rows.copy;

    return s;
}

- (instancetype)newSectionWithRowsMatchingQuery:(NSString *)query {
    // Find rows containing the search string
    NSPredicate *containsString = [NSPredicate predicateWithBlock:^BOOL(id<FLEXPatternMatching> obj, NSDictionary *bindings) {
        return [obj matches:query];
    }];
    NSArray *filteredRows = [self.rows filteredArrayUsingPredicate:containsString];
    
    // Only return new section if not empty
    if (filteredRows.count) {
        return [[self class] section:self.section title:self.title rows:filteredRows];
    }
    
    return nil;
}

- (NSInteger)count {
    return self.rows.count;
}

@end

@implementation FLEXTableViewSection (Subscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.rows[idx];
}

@end
