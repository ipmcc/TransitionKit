//
//  TKStateMachineSpec.m
//  TransitionKit
//
//  Created by Blake Watters on 3/17/13.
//  Copyright (c) 2013 Blake Watters. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Kiwi.h"
#import "TransitionKit.h"

@interface TKSpecPerson : NSObject
@property (nonatomic, assign, getter = isHappy) BOOL happy;
@property (nonatomic, assign, getter = isLookingForLove) BOOL lookingForLove;
@property (nonatomic, assign, getter = isDepressed) BOOL depressed;
@property (nonatomic, assign, getter = isDead) BOOL dead;
@property (nonatomic, assign, getter = isConsultingLawyer) BOOL consultingLawyer;
@property (nonatomic, assign, getter = wasPreviouslyMarried) BOOL previouslyMarried;
@property (nonatomic, assign, getter = isWillingToGiveUpHalfOfEverything) BOOL willingToGiveUpHalfOfEverything;

- (void)updateRelationshipStatusOnFacebook;
- (void)startDrinkingHeavily;
- (void)startTryingToPickUpCollegeGirls;
@end

@implementation TKSpecPerson
- (void)updateRelationshipStatusOnFacebook {}
- (void)startDrinkingHeavily {}
- (void)startTryingToPickUpCollegeGirls {}
@end

SPEC_BEGIN(TKStateMachineSpec)

__block TKStateMachine *stateMachine = nil;

beforeEach(^{
    stateMachine = [TKStateMachine new];
});

context(@"when initialized", ^{
    it(@"has no states", ^{
        [[stateMachine.states should] haveCountOf:0];
    });

    it(@"is not active", ^{
        [[@(stateMachine.isActive) should] beNo];
    });
    
    it(@"is not terminated", ^{
        [[@(stateMachine.terminated) should] beNo];
    });
    
    it(@"has no terminal states", ^{
        [[stateMachine.terminalStates should] haveCountOf:0];
    });

    it(@"has a nil initial state", ^{
        [[stateMachine.initialState should] beNil];
    });
    
    it(@"has no events", ^{
        [[stateMachine.events should] haveCountOf:0];
    });
    
    context(@"and a state is added", ^{
        __block TKState *state = nil;
        
        beforeEach(^{
            state = [TKState stateWithName:@"Single"];
            [stateMachine addState:state];
        });
        
        it(@"has a state count of 1", ^{
            [[stateMachine.states should] haveCountOf:1];
        });
        
        it(@"contains the state that was added", ^{
            [[stateMachine.states should] contain:state];
        });
        
        it(@"can retrieve the state by name", ^{
            TKState *fetchedState = [stateMachine stateNamed:@"Single"];
            [[fetchedState should] equal:state];
        });
        
        it(@"sets the initial state to the newly added state", ^{
            [[stateMachine.initialState should] equal:state];
        });
    });
    
    context(@"and a terminal state is added", ^{
        __block TKState *state = nil;
        
        beforeEach(^{
            state = [TKState stateWithName:@"Dead"];
            [stateMachine setTerminalStates: [NSSet setWithObject: state]];
        });
        
        it(@"has a terminalStates count of 1", ^{
            [[stateMachine.terminalStates should] haveCountOf:1];
        });
        
        it(@"contains the terminalState that was added", ^{
            [[stateMachine.terminalStates should] contain:state];
        });
        
        it(@"adds the terminalState to the main state list too", ^{
            [[stateMachine.states should] contain:state];
        });

        it(@"does NOT set the initial state to the newly added terminalState", ^{
            [[state shouldNot] equal: stateMachine.initialState];
        });
    });
    
    context(@"when an event is added", ^{
        __block TKEvent *event = nil;
        __block TKState *singleState = nil;
        __block TKState *datingState = nil;
        
        context(@"when a state referenced by the event is not added to the state machine", ^{
            it(@"raises an exception", ^{
                stateMachine = [TKStateMachine new];
                [stateMachine addState:singleState];
                event = [TKEvent eventWithName:@"Start Dating" transitioningFromStates:@[ singleState ] toState:datingState];
                [[theBlock(^{
                    [stateMachine addEvent:event];
                }) should] raiseWithName:NSInternalInconsistencyException reason:@"Cannot add event 'Start Dating' to the state machine: the event references a state 'Dating', which has not been added to the state machine."];
            });
        });
        
        beforeEach(^{
            singleState = [TKState stateWithName:@"Single"];
            datingState = [TKState stateWithName:@"Dating"];
            event = [TKEvent eventWithName:@"Start Dating" transitioningFromStates:@[ singleState ] toState:datingState];
            [stateMachine addStates:@[ singleState, datingState ]];
            [stateMachine addEvent:event];
        });
        
        it(@"has an event count of 1", ^{
            [[stateMachine.events should] haveCountOf:1];
        });
        
        it(@"contains the event that was added", ^{
            [[stateMachine.events should] contain:event];
        });
        
        it(@"can retrieve the event by name", ^{
            TKEvent *fetchedEvent = [stateMachine eventNamed:@"Start Dating"];
            [[fetchedEvent should] equal:event];
        });
    });
});

context(@"when a state machine is copied", ^{
    __block TKState *firstState;
    __block TKState *secondState;
    __block TKState *lastState;
    __block TKEvent *event;
    __block TKStateMachine *copiedStateMachine;
    
    beforeEach(^{
        firstState = [TKState stateWithName:@"First"];
        secondState = [TKState stateWithName:@"Second"];
        lastState = [TKState stateWithName:@"Last"];
        [stateMachine addStates:@[ firstState, secondState ]];
        stateMachine.terminalStates = [NSSet setWithObject: lastState];
        event = [TKEvent eventWithName:@"Event" transitioningFromStates:@[ firstState ] toState:secondState];
        [stateMachine addEvent:event];
        
        stateMachine.initialState = firstState;
        [stateMachine activate];
        
        copiedStateMachine = [stateMachine copy];
    });
    
    it(@"is not active", ^{
        [[@(copiedStateMachine.isActive) should] beNo];
    });
    
    it(@"copies all states", ^{
        [[copiedStateMachine.states should] haveCountOf:3];
        [[copiedStateMachine.states shouldNot] contain:firstState];
        [[copiedStateMachine.states shouldNot] contain:secondState];
        [[copiedStateMachine.states shouldNot] contain:lastState];
    });
    
    it(@"copies terminal states", ^{
        [[copiedStateMachine.terminalStates should] haveCountOf:1];
        [[copiedStateMachine.terminalStates shouldNot] contain:lastState];
        [[copiedStateMachine.terminalStates should] contain: [copiedStateMachine stateNamed: lastState.name]];
    });

    it(@"copies all events", ^{
        [[copiedStateMachine.events should] haveCountOf:1];
        [[copiedStateMachine.events shouldNot] contain:event];
    });
    
    it(@"copies the initial state", ^{
        [[copiedStateMachine.initialState.name should] equal:@"First"];
    });
    
    it(@"has a `nil` current state", ^{
        [[copiedStateMachine.currentState should] beNil];
    });
    
    it(@"is not terminated", ^{
        [[@(copiedStateMachine.terminated) should] beNo];
    });

});

context(@"when a state machine is serialized", ^{
});

describe(@"setting the initial state", ^{
    beforeEach(^{
        TKState *single = [TKState stateWithName:@"Single"];
        TKState *dating = [TKState stateWithName:@"Dating"];
        [stateMachine addStates:@[ single, dating ]];
        [stateMachine addEvent:[TKEvent eventWithName:@"Break Up" transitioningFromStates:@[ dating ] toState:single]];
    });
    
    context(@"when the state machine has not been started", ^{
        beforeEach(^{
            [stateMachine addState:[TKState stateWithName:@"Dating"]];
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        });
        
        it(@"sets the initial state", ^{
            [[stateMachine.initialState.name should] equal:@"Dating"];
        });
        
        it(@"does not have a current state", ^{
            [[stateMachine.currentState should] beNil];
        });
        
        context(@"and then is started", ^{
            it(@"changes the current state to the initial state", ^{
                [stateMachine activate];
                [[stateMachine.currentState.name should] equal:@"Dating"];
            });
        });
    });
    
    context(@"when the state machine has been started", ^{
        it(@"raises an exception", ^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
            [stateMachine fireEvent:@"Break Up" userInfo:nil error:nil];
            [[theBlock(^{
                stateMachine.initialState = [stateMachine stateNamed:@"Married"];
            }) should] raiseWithName:TKStateMachineIsImmutableException reason:@"Unable to modify state machine: The state machine has already been activated."];
        });
    });
});

describe(@"addState:", ^{
    context(@"when given an object that is not a TKState", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine addState:(TKState *)@1234];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected a `TKState` object or `NSString` object specifying the name of a state, instead got a `__NSCFNumber` (1234)"];
        });
    });
});

describe(@"setInitialState:", ^{
    context(@"when given an object that is not a TKState", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine setInitialState:(TKState *)@1234];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected a `TKState` object, instead got a `__NSCFNumber` (1234)"];
        });
    });
});

describe(@"setTerminalStates:", ^{
    context(@"when given an object that is not an NSSet", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine setTerminalStates:(NSSet *)@1234];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected an `NSSet` object specifying the terminal states, instead got a `__NSCFNumber` (1234)"];
        });
    });
});

describe(@"setTerminalStates:", ^{
    context(@"when given a set containing an object that is not a TKState", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine setTerminalStates: [NSSet setWithObject: @1234]];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected an `NSSet` of `TKState` objects, but the set contains a `__NSCFNumber` (1234)"];
        });
    });
});

describe(@"setTerminalStates:", ^{
    context(@"when given nil", ^{
        stateMachine.terminalStates = nil;
        [[stateMachine.terminalStates should] beNonNil];
        [[stateMachine.terminalStates should] haveCountOf: 0];
        [[stateMachine.terminalStates should] beMemberOfClass: [NSSet class]];
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine setTerminalStates: [NSSet setWithObject: @1234]];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected an `NSSet` of `TKState` objects, but the set contains a `__NSCFNumber` (1234)"];
        });
    });
});


describe(@"isInState:", ^{
    context(@"when given an object that is not a TKState or an NSString", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine isInState:(TKState *)@1234];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Expected a `TKState` object or `NSString` object specifying the name of a state, instead got a `__NSCFNumber` (1234)"];
        });
    });
    
    context(@"when given a NSString that is not the name of a registered state", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [stateMachine isInState:@"Invalid"];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"Cannot find a State named 'Invalid'"];
        });
    });
});

describe(@"fireEvent:userInfo:error", ^{
    __block TKState *singleState;
    __block TKState *datingState;
    __block TKState *deadState;

    beforeEach(^{
        singleState = [TKState stateWithName:@"Single"];
        datingState = [TKState stateWithName:@"Dating"];
        deadState = [TKState stateWithName:@"Dead"];
        [stateMachine addStates:@[ singleState, datingState ]];
        stateMachine.terminalStates = [NSSet setWithObject:deadState];
        [stateMachine addEvent:[TKEvent eventWithName:@"Break Up" transitioningFromStates:@[ datingState ] toState:singleState]];
        [stateMachine addEvent:[TKEvent eventWithName:@"Death" transitioningFromStates:nil toState:deadState]];
        [stateMachine addEvent:[TKEvent eventWithName:@"Resurrection" transitioningFromStates: @[ deadState ] toState: singleState]];
        stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        [stateMachine activate];
    });

    it(@"invokes callbacks with a TKTransition describing the state change", ^{
        __block TKTransition *blockTransition;
        [singleState setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
            NSLog(@"dsfdsfds");
            blockTransition = transition;
        }];
        NSError *error = nil;
        BOOL success = [stateMachine fireEvent:@"Break Up" userInfo:nil error:&error];
        [[theValue(success) should] beTrue];
        [[blockTransition shouldNot] beNil];
        [[blockTransition.stateMachine should] equal:stateMachine];
        [[blockTransition.sourceState should] equal:datingState];
        [[blockTransition.destinationState should] equal:singleState];
        [[blockTransition.event.name should] equal:@"Break Up"];
    });

    it(@"does not transition into a terminated state after entering a non-terminal state", ^{
        NSError *error = nil;
        BOOL success = [stateMachine fireEvent:@"Break Up" userInfo:nil error:&error];
        [[theValue(success) should] beTrue];
        
        BOOL terminated = stateMachine.terminated;
        [[theValue(terminated) should] beFalse];
    });

    it(@"transitions into a terminated state after entering a terminal state", ^{
        NSError *error = nil;
        BOOL success = [stateMachine fireEvent:@"Death" userInfo:nil error:&error];
        [[theValue(success) should] beTrue];
        [[error should] beNil];

        BOOL terminated = stateMachine.terminated;
        [[theValue(terminated) should] beTrue];        
    });

    it(@"should refuse further events after being terminated", ^{
        NSError *error = nil;
        BOOL success = [stateMachine fireEvent:@"Death" userInfo:nil error:&error];
        [[theValue(success) should] beTrue];
        [[error should] beNil];

        BOOL terminated = stateMachine.terminated;
        [[theValue(terminated) should] beTrue];

        BOOL canFire = [stateMachine canFireEvent: @"Resurrection"];
        [[theValue(canFire) should] beFalse];
        
        success = [stateMachine fireEvent:@"Resurrection" userInfo:nil error: &error];
        [[theValue(success) should] beFalse];
        [[error should] beNonNil];
        [[error.domain should] equal: TKErrorDomain];
        [[@(error.code) should] equal: @(TKStateMachineTerminatedError)];
    });
    
    it(@"should send a notification when entering a terminal state", ^{
        __block NSNotification *notification = nil;
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:nil usingBlock:^(NSNotification *note) {
            notification = note;
        }];
        
        NSError *error = nil;
        BOOL success = [stateMachine fireEvent:@"Death" userInfo:nil error:&error];

        [[theValue(success) should] beTrue];
        [[error should] beNil];
        [[expectFutureValue(notification) shouldEventually] beNonNil];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    });


    context(@"with userInfo", ^{
        it(@"includes the userInfo in the transition", ^{
            __block TKTransition *blockTransition;
            [singleState setWillExitStateBlock:^(TKState *state, TKTransition *transition) {
                blockTransition = transition;
            }];
            [stateMachine fireEvent:@"Break Up" userInfo:@{ @"reason": @"It's not you, it's me" } error:nil];
        });

        it(@"merges the userInfo into the posted NSNotification", ^{
            __block NSNotification *notification = nil;
            id observer = [[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:nil usingBlock:^(NSNotification *note) {
                notification = note;
            }];
            [stateMachine fireEvent:@"Break Up" userInfo:@{ @"songPlayingOnRepeat": @"What is love, when you don't hurt me?" } error:nil];
            [[expectFutureValue(notification) shouldEventually] beNonNil];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            [[notification.userInfo[@"songPlayingOnRepeat"] should] equal:@"What is love, when you don't hurt me?"];
        });

        it(@"merges the userInfo when posting the notification for termination", ^{
            __block NSNotification *notification = nil;
            id observer = [[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:nil usingBlock:^(NSNotification *note) {
                notification = note;
            }];
            
            [stateMachine fireEvent:@"Death" userInfo:@{ @"reason for death" : @"heartbreak" } error: NULL];
            [[expectFutureValue(notification) shouldEventually] beNonNil];
            [[notification.userInfo[@"reason for death"] should] equal:@"heartbreak"];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        });

        
    });
});

describe(@"A State Machine Modeling Dating", ^{
    __block TKSpecPerson *person;
    __block TKState *singleState;
    __block TKState *datingState;
    __block TKState *marriedState;
    __block TKState *deadState;
    __block TKEvent *startDating;
    __block TKEvent *breakup;
    __block TKEvent *getMarried;
    __block TKEvent *divorce;
    __block TKEvent *die;
    
    beforeEach(^{
        person = [TKSpecPerson new];
        
        stateMachine = [TKStateMachine new];
        singleState = [TKState stateWithName:@"Single"];
        [singleState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
            person.lookingForLove = YES;
        }];
        [singleState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
            person.lookingForLove = NO;
        }];
        datingState = [TKState stateWithName:@"Dating"];
        [datingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
            person.happy = YES;
        }];
        [datingState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
            person.happy = NO;
        }];
        marriedState = [TKState stateWithName:@"Married"];
        deadState = [TKState stateWithName: @"Dead"];

        [stateMachine addStates:@[ singleState, datingState, marriedState ]];
        stateMachine.terminalStates = [NSSet setWithObject: deadState];
        
        startDating = [TKEvent eventWithName:@"Start Dating" transitioningFromStates:@[ singleState ] toState:datingState];
        [startDating setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
            [person updateRelationshipStatusOnFacebook];
        }];
        breakup = [TKEvent eventWithName:@"Break Up" transitioningFromStates:@[ datingState ] toState:singleState];
        [breakup setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
            [person updateRelationshipStatusOnFacebook];
            [person startDrinkingHeavily];
        }];
        getMarried = [TKEvent eventWithName:@"Get Married" transitioningFromStates:@[ datingState ] toState:marriedState];
        divorce = [TKEvent eventWithName:@"Divorce" transitioningFromStates:@[ marriedState ] toState:singleState];
        [divorce setWillFireEventBlock:^(TKEvent *event, TKTransition *transition) {
            person.consultingLawyer = YES;
        }];
        [divorce setShouldFireEventBlock:^BOOL(TKEvent *event, TKTransition *transition) {
            return person.isWillingToGiveUpHalfOfEverything;
        }];
        [divorce setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
            person.consultingLawyer = NO;
            [person startDrinkingHeavily];
            [person startTryingToPickUpCollegeGirls];
        }];
        die = [TKEvent eventWithName:@"Die" transitioningFromStates: nil toState: deadState];
        [die setDidFireEventBlock:^(TKEvent *event, TKTransition *transition) {
            person.dead = YES;
        }];
        [stateMachine addEvents:@[ startDating, breakup, getMarried, divorce, die ]];
    });
    
    context(@"when a Single Person Starts Dating", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Single"];
            [stateMachine activate];
        });
        
        it(@"transitions to the Dating state", ^{
            [stateMachine fireEvent:@"Start Dating" userInfo:nil error:nil];
            [[stateMachine.currentState.name should] equal:@"Dating"];
        });
        
        it(@"returns YES", ^{
            BOOL success = [stateMachine fireEvent:@"Start Dating" userInfo:nil error:nil];
            [[@(success) should] beYes];
        });
        
        it(@"returns a nil error", ^{
            NSError *error = nil;
            [stateMachine fireEvent:@"Start Dating" userInfo:nil error:&error];
            [[error should]  beNil];
        });
        
        it(@"is no longer looking for love", ^{
            [[@(person.isLookingForLove) should] beYes];
            [stateMachine fireEvent:@"Start Dating" userInfo:nil error:nil];
            [[@(person.isLookingForLove) should] beNo];
        });
        
        it(@"is happy", ^{
            [[@(person.isHappy) should] beNo];
            [stateMachine fireEvent:@"Start Dating" userInfo:nil error:nil];
            [[@(person.isHappy) should] beYes];
        });
        
        it(@"delivers a notification", ^{
            __block NSNotification *notification = nil;
            id observer = [[NSNotificationCenter defaultCenter] addObserverForName:TKStateMachineDidChangeStateNotification object:stateMachine queue:nil usingBlock:^(NSNotification *note) {
                notification = note;
            }];
            [stateMachine fireEvent:@"Start Dating" userInfo:nil error:nil];
            [[expectFutureValue(notification) shouldEventually] beNonNil];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            [[notification.userInfo should] beNonNil];
            [[[[notification.userInfo objectForKey:TKStateMachineDidChangeStateOldStateUserInfoKey] name] should] equal:@"Single"];
            [[[[notification.userInfo objectForKey:TKStateMachineDidChangeStateNewStateUserInfoKey] name] should] equal:@"Dating"];
            [[[[notification.userInfo objectForKey:TKStateMachineDidChangeStateEventUserInfoKey] name] should] equal:@"Start Dating"];
        });
    });
    
    context(@"when a Dating Person Breaks Up", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        });
        
        it(@"updates their relationship status on Facebook", ^{
            [[person should] receive:@selector(updateRelationshipStatusOnFacebook)];
            [stateMachine fireEvent:@"Break Up" userInfo:nil error:nil];
        });
        
        it(@"starts drinking heavily", ^{
            [[person should] receive:@selector(startDrinkingHeavily)];
            [stateMachine fireEvent:@"Break Up" userInfo:nil error:nil];
        });
        
        it(@"starts looking for love", ^{
            [stateMachine fireEvent:@"Break Up" userInfo:nil error:nil];
            [[@(person.isLookingForLove) should] beYes];
        });
        
        it(@"becomes unhappy", ^{
            [stateMachine fireEvent:@"Break Up" userInfo:nil error:nil];
            [[@(person.isHappy) should] beNo];
        });
    });
    
    context(@"when a Dating Person Gets Married", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        });
    });
    
    context(@"when a Married Person Divorces", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Married"];
            [stateMachine activate];
        });
        
        context(@"but is unwilling to give up half of everything", ^{
            beforeEach(^{
                person.willingToGiveUpHalfOfEverything = NO;
            });
            
            it(@"can be fired", ^{
                [[@([stateMachine canFireEvent:@"Divorce"]) should] beYes];
            });
            
            it(@"fails to fire the event", ^{
                [[@([stateMachine fireEvent:@"Divorce" userInfo:nil error:nil]) should] beNo];
            });
            
            it(@"fails with a TKTransitionDeclinedError", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:&error];
                [[@(error.code) should] equal:@(TKTransitionDeclinedError)];
            });
            
            it(@"sets a description on the error", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:&error];
                [[error.localizedDescription should] equal:@"The event declined to be fired."];
            });
            
            it(@"sets a failure reason on the error", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:&error];
                [[error.localizedFailureReason should] equal:@"An attempt to fire the 'Divorce' event was declined because `shouldFireEventBlock` returned `NO`."];
            });
            
            it(@"stays married", ^{
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:nil];
                [[stateMachine.currentState.name should] equal:@"Married"];
            });
        });
        
        context(@"when willing to give up half of everything", ^{
            beforeEach(^{
                person.willingToGiveUpHalfOfEverything = YES;
            });
            
            it(@"can be fired", ^{
                [[@([stateMachine canFireEvent:@"Divorce"]) should] beYes];
            });
            
            it(@"consults a lawyer during the divorce", ^{
                [[person should] receive:@selector(setConsultingLawyer:) withArguments:theValue(YES)];
                [[person should] receive:@selector(setConsultingLawyer:) withArguments:theValue(NO)];
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:nil];
            });
            
            it(@"transitions to the Single state", ^{
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:nil];
                [[stateMachine.currentState.name should] equal:@"Single"];
            });
            
            it(@"starts drinking heavily", ^{
                [[person should] receive:@selector(startDrinkingHeavily)];
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:nil];
            });
            
            it(@"starts trying to pick up college girls", ^{
                [[person should] receive:@selector(startTryingToPickUpCollegeGirls)];
                [stateMachine fireEvent:@"Divorce" userInfo:nil error:nil];
            });
        });
    });
    
    // Invalid Transitions
    context(@"when a Single Person tries to Break Up", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Single"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Break Up"]) should] beNo];
        });
        
        context(@"when fired", ^{
            it(@"returns NO", ^{
                [[@([stateMachine fireEvent:@"Break Up" userInfo:nil error:nil]) should] beNo];
            });
            
            it(@"sets an TKInvalidTransitionError error", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Break Up" userInfo:nil error:&error];
                [[@(error.code) should] equal:@(TKInvalidTransitionError)];
            });
            
            it(@"sets an informative description on the error", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Break Up" userInfo:nil error:&error];
                [[[error localizedDescription] should] equal:@"The event cannot be fired from the current state."];
            });
            
            it(@"sets an informative failure reason on the error", ^{
                NSError *error = nil;
                [stateMachine fireEvent:@"Break Up" userInfo:nil error:&error];
                [[[error localizedFailureReason] should] equal:@"An attempt was made to fire the 'Break Up' event while in the 'Single' state, but the event can only be fired from the following states: Dating"];
            });
        });
    });
    
    context(@"when a Dead Person tries to do anything", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dead"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Get Married"]) should] beNo];
        });
        
        it(@"is terminated", ^{
            [stateMachine activate];
            [[@(stateMachine.terminated) should] beYes];
        });
        
    });
    
    context(@"when a Single Person tries to Get Married", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Single"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Get Married"]) should] beNo];
        });
    });
    
    context(@"when a Single Person tries to Divorce", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Single"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Divorce"]) should] beNo];
        });
    });
    
    context(@"when a Dating Person tries to Divorce", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Divorce"]) should] beNo];
        });
    });
    
    context(@"when a Dating Person tries to Start Dating", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Dating"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Start Dating"]) should] beNo];
        });
    });
    
    context(@"when a Married Person tries to Break Up", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Married"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Break Up"]) should] beNo];
        });
    });
    
    context(@"when a Married Person tries to Start Dating", ^{
        beforeEach(^{
            stateMachine.initialState = [stateMachine stateNamed:@"Married"];
        });
        
        it(@"cannot be fired", ^{
            [[@([stateMachine canFireEvent:@"Start Dating"]) should] beNo];
        });
    });
});

SPEC_END
