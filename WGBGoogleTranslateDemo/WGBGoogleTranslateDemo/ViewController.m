//
//  ViewController.m
//  WGBGoogleTranslateDemo
//
//  Created by 王贵彬 on 2018/8/7.
//  Copyright © 2018年 王贵彬. All rights reserved.
//

#import "ViewController.h"
#import "WGBGoogleSpeechManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
//录制
- (IBAction)recordAction:(UIButton *)sender {
	[[WGBGoogleSpeechManager shareDefault] setRecordLanguageCode:WGBGoogleLanguageTypeChinese]; //请说中文
	[[WGBGoogleSpeechManager shareDefault] startRecordAction];
}

//语音识别
- (IBAction)speechRecognitionAtion:(id)sender {
	[[WGBGoogleSpeechManager shareDefault] stopRecordAction];
	[[WGBGoogleSpeechManager shareDefault] setGetSpeechRecognizeContentBlock:^(NSString *content) {//识别结果为中文
		  self.textView.text = content;
	}];
}

//文本翻译
- (IBAction)textTrantionAction:(id)sender {
	[[WGBGoogleSpeechManager shareDefault] translateOriginText: self.textView.text targetCode:@(WGBGoogleLanguageTypeEnglish).stringValue.googleLanguageCode callBack:^(NSString *objStr) {
		self.textView.text = objStr; //翻译结果为英文
	}];
}

//语音合成
- (IBAction)speechSynthesisAction:(UIButton *)sender {
	[[WGBGoogleSpeechManager shareDefault] setPlayLanguageCode: WGBGoogleLanguageTypeEnglish]; //播放语音 英文发音
	[[WGBGoogleSpeechManager shareDefault] playAudioWithTranslateWithTextContent: self.textView.text];
}

@end
