#import "TextFieldFormHandler.h"

@interface TextFieldFormHandler()
@property (strong, nonatomic) NSArray *textFields;
@property (nonatomic) NSInteger keyboardSize;
@property (nonatomic) NSInteger animationOffset;
@property (nonatomic) UIView *topContainer;
@end

@implementation TextFieldFormHandler
- (instancetype)initWithTextFields:(NSArray<UITextField *> *)textfields topContainer:(UIView *)view {
  self = [self init];
  if (self) {
    self.topContainer = view;
    self.textFields = textfields;
    [self initializeTextFields];
    [self initializeObjervers];
  }
  return self;
}

- (void)dealloc {
  [self cleanUp];
}

- (void)initializeObjervers {
  [[NSNotificationCenter defaultCenter]
    addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
    initWithTarget:self action:@selector(backgroundTap:)];
  [self.topContainer addGestureRecognizer:tapGestureRecognizer];
}

- (void)cleanUp {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializeTextFields {
  NSInteger count = self.textFields.count;
  [self.textFields enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    UITextField *textField = (UITextField *)obj;
    textField.delegate = self;
    [self setTextField:textField returnKeyType:(idx < count - 1) ? UIReturnKeyNext : UIReturnKeyDone];
  }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if ((self.lastTextField && self.lastTextField == textField) || textField == self.textFields.lastObject) {
    [self doneEnteringData];
    return YES;
  }
  
  NSInteger index = [self.textFields indexOfObject:textField];
  UITextField *nextTextField = (UITextField *)self.textFields[index + 1];
  [nextTextField becomeFirstResponder];
  
  return YES;
}

- (void)doneEnteringData {
  [self.topContainer endEditing:YES];
  [self moveScreenDown];
  if ([self.delegate respondsToSelector:@selector(textFieldFormHandlerDoneEnteringData:)]) {
    [self.delegate textFieldFormHandlerDoneEnteringData:self];
  }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  [self setAnimationOffsetForTextField:textField];
  return YES;
}

- (void)setAnimationOffsetForTextField:(UITextField *)textField {
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
  CGFloat textFieldHeight = CGRectGetHeight(textField.frame);
  CGFloat textFieldY = [textField convertPoint:CGPointZero toView:self.topContainer].y;
  self.animationOffset = -screenHeight + textFieldY + textFieldHeight;
}

- (void)keyboardWillShow:(NSNotification *)notification {
  if (self.keyboardSize == 0.f) {
    CGSize keyboardSize = [[notification userInfo][UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.keyboardSize = MIN(keyboardSize.height, keyboardSize.width);
  }
  [self moveScreenUp];
}

- (void)resetScroll {
  [self setAnimationOffsetForTextField:self.firstResponder];
  [self moveScreenUp];
}

- (void)setTextFieldAtIndexAsFirstResponder:(NSInteger)index {
  [self.textFields[index] becomeFirstResponder];
}

- (NSInteger)firstResponderIndex {
  return [self.textFields indexOfObject:[self firstResponder]];
}

- (UITextField *)firstResponder {
  NSPredicate *predIsFirstResponder = [NSPredicate predicateWithFormat:@"isFirstResponder == YES"];
  NSArray *firstResponderList = [self.textFields filteredArrayUsingPredicate:predIsFirstResponder];
  return firstResponderList.firstObject;
}

- (void)moveScreenUp
{
  [self shiftScreenYPosition:-self.keyboardSize - self.animationOffset withDuration:0.30 curve: UIViewAnimationCurveEaseInOut];
}

- (void)moveScreenDown
{
  [self shiftScreenYPosition:0 withDuration:0.20 curve: UIViewAnimationCurveEaseInOut];
}

- (void)shiftScreenYPosition: (NSInteger)position withDuration: (CGFloat) duration curve: (UIViewAnimationCurve) curve {
  [UIView beginAnimations:@"moveUp" context:NULL];
  [UIView setAnimationCurve:curve];
  [UIView setAnimationDuration:duration];
  
  CGRect rect = self.topContainer.frame;
  rect.origin.y = MIN(position, 0);
  self.topContainer.frame = rect;
  
  [UIView commitAnimations];
}

- (void)backgroundTap:(id)sender {
  [self.topContainer endEditing:YES];
  [self moveScreenDown];
}

- (void)setTextField:(UITextField *)textField returnKeyType:(UIReturnKeyType)type {
  BOOL isFirstResponder = textField.isFirstResponder;
  if (isFirstResponder) [textField resignFirstResponder];
  textField.returnKeyType = type;
  if (isFirstResponder) [textField becomeFirstResponder];
}

- (void)setLastTextField:(UITextField *)lastTextField {
  if (_lastTextField) {
    [self setTextField:_lastTextField returnKeyType:UIReturnKeyNext];
  }
  
  _lastTextField = lastTextField;
  
  UITextField *textField = (_lastTextField ? _lastTextField : self.textFields[self.textFields.count - 1]);
  [self setTextField:textField returnKeyType:UIReturnKeyDone];
}


@end
