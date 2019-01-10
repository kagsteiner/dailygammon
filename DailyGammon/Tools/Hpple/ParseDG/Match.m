//
//  Match.m
//  DailyGammon
//
//  Created by Peter on 16.12.18.
//  Copyright © 2018 Peter Schneider. All rights reserved.
//

#import "Match.h"
#import "TFHpple.h"

@implementation Match

-(NSMutableDictionary *) readMatch:(NSString *)matchLink
{
    NSMutableDictionary *boardDict = [[NSMutableDictionary alloc]init];
    
#pragma mark - matchName
    NSURL *urlMatch = [NSURL URLWithString:[NSString stringWithFormat:@"http://dailygammon.com%@",matchLink]];
    
    NSData *matchHtmlData = [NSData dataWithContentsOfURL:urlMatch];
    NSError *error = nil;
    NSStringEncoding encoding = 0;
    NSString *matchString = [[NSString alloc] initWithContentsOfURL:urlMatch
                                                       usedEncoding:&encoding
                                                              error:&error];
    if(error)
        XLog(@"%@", urlMatch);
    
    NSData *data = [NSData dataWithContentsOfURL:urlMatch];
    
    // wie bekomme ich nur sauber die Sonderzeichen gelesen???
    NSString *htmlString = [NSString stringWithUTF8String:[data bytes]];
    htmlString = [[NSString alloc]
              initWithData:data encoding: NSISOLatin1StringEncoding];
    
    NSString *chat = @"";
    NSRange preStart = [htmlString rangeOfString:@"<PRE>"];
    if(preStart.length > 0)
    {
        NSRange preEnd = [htmlString rangeOfString:@"</PRE>"];
        NSRange rangeChat = NSMakeRange(preStart.location + preStart.length, preEnd.location - preStart.location - preStart.length);
        chat = [htmlString substringWithRange:rangeChat];
        chat = [chat stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    }
    NSData *htmlData = [htmlString dataUsingEncoding:NSUnicodeStringEncoding];

    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:matchHtmlData ] ;
    
    xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData ] ;

#pragma mark - The http request you submitted was in error.
    NSString *errorText = @"";
    if ([matchString rangeOfString:@"The http request you submitted was in error."].location != NSNotFound)
    {
        errorText = @"The http request you submitted was in error.";
        [boardDict setObject:errorText forKey:@"error"];
//        return boardDict;
    }

    NSArray *matchHeader  = [xpathParser searchWithXPathQuery:@"//h3"];
    NSMutableString *matchName = [[NSMutableString alloc]init];
    for(TFHppleElement *element in matchHeader)
    {
        for (TFHppleElement *child in element.children)
        {
            [matchName appendString:[child content]];
        }
    }
    [boardDict setObject:matchName forKey:@"matchName"];
    [boardDict setObject:chat forKey:@"chat"];
    
#pragma mark -     You have received the following telegram message:
//    [boardDict setObject:@"You have received the following telegram message:" forKey:@"message"];
//    [boardDict setObject:@"!DailyGammon is pleased to announce that the Three Pointer #3317 tournament has begun.  Good luck!" forKey:@"chat"];
#warning "You have received the following telegram message:" abfangen
    if ([matchString rangeOfString:@"telegram"].location != NSNotFound)
    {
        [boardDict setObject:@"You have received the following telegram message:" forKey:@"message"];
        // in "chat" sollte dann der text stehen
        return boardDict;
    }
    
#pragma mark - unexpected Move
    NSString *unexpectedMove = @"";
    if ([matchString rangeOfString:@"unexpected"].location != NSNotFound)
        unexpectedMove = @"Your opponent made an unexpected move, and the game has been rolled back to that point.";
    [boardDict setObject:unexpectedMove forKey:@"unexpectedMove"];

#pragma mark - obere Nummern Reihe
    NSArray *elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[1]/td"];
    NSMutableArray *elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        [elementArray addObject:[element text]];
    }
    [boardDict setObject:elementArray forKey:@"nummernOben"];
    
#pragma mark - obere Grafik Reihe
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[2]/td"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        NSString *image = @"";
        NSString *href = @"";
        NSMutableArray *imgArray = [[NSMutableArray alloc]init];
        for (TFHppleElement *child in element.children)
        {
            NSDictionary *hrefChild = [child attributes];
            href = [hrefChild objectForKey:@"href"];
            TFHppleElement *childFirst = [child firstChild];
            NSDictionary *imgChild = [childFirst attributes];
            image = [imgChild objectForKey:@"src"];
            if ([child.tagName isEqualToString:@"img"])
            {
                image = [child objectForKey:@"src"];
                [imgArray addObject:image];
            }
            if(imgArray.count == 0)
                if(image != nil)
                    [imgArray addObject:image];
            
        }
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:imgArray forKey:@"img"];
        [dict setValue:href forKey:@"href"];
        
        [elementArray addObject:dict];
    }
    [boardDict setObject:elementArray forKey:@"grafikOben"];
    
#pragma mark - opponent
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[2]/td[17]"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        for (TFHppleElement *child in element.children)
        {
            [elementArray addObject:[child content]];
        }
    }
    [boardDict setObject:elementArray forKey:@"opponent"];
    
#pragma mark - obere Reihe moveIndicator
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[3]/td"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        NSString *image = @"";
        for (TFHppleElement *child in element.children)
        {
            if ([child.tagName isEqualToString:@"img"])
            {
                image = [child objectForKey:@"src"];
            }
        }
        [elementArray addObject:image];
    }
    [boardDict setObject:elementArray forKey:@"moveIndicatorOben"];
    
#pragma mark - Würfel Reihe
#warning colspan macht evtl. noch Probleme
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[4]/td"];
    elementArray = [[NSMutableArray alloc]init];
    NSString *matchLaengeText = @"?";
    for(TFHppleElement *element in elements)
    {
        matchLaengeText = [element  content]; // im letzten TD steht "3 Point Match"
        [boardDict setObject:matchLaengeText forKey:@"matchLaengeText"];

        NSString *image = @"";
        for (TFHppleElement *child in element.children)
        {
            if ([child.tagName isEqualToString:@"img"])
            {
                image = [child objectForKey:@"src"];
            }
        }
        [elementArray addObject:image];
    }
    [boardDict setObject:elementArray forKey:@"dice"];
    
#pragma mark - untere Reihe moveIndicator
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[5]/td"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        NSString *image = @"";
        for (TFHppleElement *child in element.children)
        {
            if ([child.tagName isEqualToString:@"img"])
            {
                image = [child objectForKey:@"src"];
            }
        }
        [elementArray addObject:image];
    }
    [boardDict setObject:elementArray forKey:@"moveIndicatorUnten"];
    
#pragma mark - untere Grafik Reihe
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[6]/td"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        NSString *image = @"";
        NSString *href = @"";
        NSMutableArray *imgArray = [[NSMutableArray alloc]init];
        for (TFHppleElement *child in element.children)
        {
            NSDictionary *hrefChild = [child attributes];
            href = [hrefChild objectForKey:@"href"];
            TFHppleElement *childFirst = [child firstChild];
            NSDictionary *imgChild = [childFirst attributes];
            image = [imgChild objectForKey:@"src"];
            if ([child.tagName isEqualToString:@"img"])
            {
                image = [child objectForKey:@"src"];
                [imgArray addObject:image];
            }
            if(imgArray.count == 0)
                if(image != nil)
                    [imgArray addObject:image];
        }
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:imgArray forKey:@"img"];
        [dict setValue:href forKey:@"href"];
        
        [elementArray addObject:dict];
    }
    [boardDict setObject:elementArray forKey:@"grafikUnten"];
    
#pragma mark - player
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[6]/td[17]"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        for (TFHppleElement *child in element.children)
        {
            [elementArray addObject:[child content]];
        }
    }
    [boardDict setObject:elementArray forKey:@"player"];
    
#pragma mark - untere Nummern Reihe
    elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tr[7]/td"];
    elementArray = [[NSMutableArray alloc]init];
    
    for(TFHppleElement *element in elements)
    {
        if([element text] != nil)
            [elementArray addObject:[element text]];
    }
    [boardDict setObject:elementArray forKey:@"nummernUnten"];
    
    return boardDict;
}

-(NSMutableDictionary *) readActionForm:(NSString *)matchLink withChat:(NSString *)chat
{
    NSMutableDictionary *actionDict = [[NSMutableDictionary alloc]init];
    NSMutableArray *attributesArray = [[NSMutableArray alloc]init ];
    NSURL *urlMatch = [NSURL URLWithString:[NSString stringWithFormat:@"http://dailygammon.com%@",matchLink]];
    
    NSData *matchHtmlData = [NSData dataWithContentsOfURL:urlMatch];
    
    // vv nur zum testen um zu sehen, warum es immer wieder unbekannte action gibt
    NSString *htmlString = [[NSString alloc]
                  initWithData:matchHtmlData encoding: NSISOLatin1StringEncoding];
    [actionDict setObject:htmlString forKey:@"htmlString"];
    // ^^
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:matchHtmlData];
    NSArray *elements  = [xpathParser searchWithXPathQuery:@"//form[1]"];
    [actionDict setObject:elements forKey:@"elements"];

    for(TFHppleElement *element in elements)
    {
        if([[element raw] rangeOfString:@"textarea"].location != NSNotFound)
        {
            NSArray *pre  = [xpathParser searchWithXPathQuery:@"//pre"];
            actionDict = [self analyzeChat:element withChat:chat];
        }
        else
        {
            NSDictionary *elementDict = [element attributes];
            [actionDict setValue:[elementDict objectForKey:@"action"] forKey:@"action"];
            for (TFHppleElement *child in [element children])
            {
                NSDictionary *dict = [child attributes];
                if([dict objectForKey:@"value"])
                    [attributesArray addObject:dict];
            }
            [actionDict setObject:attributesArray forKey:@"attributes"];
            [actionDict setObject:[element content] forKey:@"content"];
        }
    }

    elements  = [xpathParser searchWithXPathQuery:@"//h4"];
    for(TFHppleElement *element in elements)
    {
        [actionDict setObject:[element content] forKey:@"Message"];
    }

    elements  = [xpathParser searchWithXPathQuery:@"//a"];
    for(TFHppleElement *element in elements)
    {
        if([[element content] isEqualToString:@"Skip Game"])
        {
            [actionDict setObject:[element objectForKey:@"href"] forKey:@"SkipGame"];
        }
        if([[element content] isEqualToString:@"Swap Dice"])
        {
            [actionDict setObject:[element objectForKey:@"href"] forKey:@"SwapDice"];
        }
        if([[element content] isEqualToString:@"Undo Move"])
        {
            [actionDict setObject:[element objectForKey:@"href"] forKey:@"UndoMove"];
        }
        if([[element content] isEqualToString:@"Next Game>&gt"])
        {
            [actionDict setObject:[element objectForKey:@"href"] forKey:@"Next Game>>"];
        }
    }
    [actionDict setObject:elements forKey:@"a"];

    return actionDict;

}

- (NSMutableDictionary *) analyzeChat:(TFHppleElement *)element withChat:(NSString *)chat
{
    NSMutableDictionary *actionDict = [[NSMutableDictionary alloc]init];
    NSMutableArray *attributesArray = [[NSMutableArray alloc]init ];

    NSDictionary *elementDict = [element attributes];
    [actionDict setValue:[elementDict objectForKey:@"action"] forKey:@"action"];
    for (TFHppleElement *child in [element children])
    {
        NSDictionary *dict = [child attributes];
        NSMutableArray *childArray = [[NSMutableArray alloc]init ];

        for (TFHppleElement *childChild in [child children])
        {
            [childArray addObject:[childChild attributes]];
        }
        [actionDict setObject:childArray forKey:@"childArray"];
        if(dict.count >0)
            [attributesArray addObject:dict];
    }
    [actionDict setObject:attributesArray forKey:@"attributes"];
    if([element content] != nil)
        [actionDict setObject:[element content] forKey:@"content"];
    else
        [actionDict setObject:chat forKey:@"content"];

    return actionDict;
}
@end