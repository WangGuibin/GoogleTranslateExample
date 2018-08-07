//
//  WGBGoogleSpeechManager.m
//  Created by CoderWGB on 2018/8/3.
//  Copyright © 2018年 DoubleMonkeyTechnology. All rights reserved.
//

#import "WGBGoogleSpeechManager.h"
#import <FSAudioStream.h>
#import <AVFoundation/AVFoundation.h>

#define weakify(x) 	 autoreleasepool{}  __weak typeof(x) weak##x = x;
#define strongify(x)  autoreleasepool{}  __strong typeof(x)  x = weak##x;

#define API_KEY @"请到google平台注册API_KEY,此服务需要翻墙使用"
#define SAMPLE_RATE 16000



@interface WGBGoogleSpeechManager()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic,copy) NSString *recordCode; //录制语言类型编码
@property (nonatomic,copy) NSString *playCode; //播放语言类型编码

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong) FSAudioStream *audioPlayer ;

@end

@implementation WGBGoogleSpeechManager

static WGBGoogleSpeechManager *_manager = nil ;
///MARK:- 做成单例
+ (instancetype)shareDefault{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[WGBGoogleSpeechManager alloc] init];
        [_manager initConfigSettings];
    });
    return _manager;
}

- (FSAudioStream *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [[FSAudioStream alloc] init];
        [_audioPlayer setVolume: 1.0f];
    }
    return _audioPlayer;
}

///MARK:- 存放录音文件路径
- (NSString *) soundFilePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    return [docsDir stringByAppendingPathComponent:@"sound.caf"];
}

///MARK:- 初始化设置
- (void)initConfigSettings{
    NSURL *soundFileURL = [NSURL fileURLWithPath:[self soundFilePath]];
    NSDictionary *recordSettings = @{AVEncoderAudioQualityKey:@(AVAudioQualityMax),
                                     AVEncoderBitRateKey: @16,
                                     AVNumberOfChannelsKey: @1,
                                     AVSampleRateKey: @(SAMPLE_RATE)};
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc]
                      initWithURL:soundFileURL
                      settings:recordSettings
                      error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }

}

///MARK:- 设置语言
- (void)setRecordLanguageCode:(WGBGoogleLanguageType)langCode{
    self.recordCode = @(langCode).stringValue.googleLanguageCode;
}

///MARK:- 设置播放语言
- (void)setPlayLanguageCode:(WGBGoogleLanguageType)langCode{
    self.playCode = @(langCode).stringValue.googleLanguageCode;
}

///MARK:- 开始录音
- (void)startRecordAction{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.audioRecorder record];
}

///MARK:- 停止录音
- (void)stopRecordAction{
    if (self.audioRecorder.recording) {
        [self.audioRecorder stop];
			@weakify(self);
			[self translateBestConfidenceContent:^(NSString *content) {
           @strongify(self);
            !self.getSpeechRecognizeContentBlock?:self.getSpeechRecognizeContentBlock(content);
        }];
    }
}

/*
 {
     "results": [
         {
             "alternatives": [
                 {
                     "transcript": "今天天气很好今天天气很不错晚上吃点什么呢",
                     "confidence": 0.9675641
                 },
                 {
                     "transcript": "今天天气很好今天的天气很不错晚上吃点什么呢",
                     "confidence": 0.93601805
                 },
                 {
                     "transcript": "今天天气很好今天天气很不错晚上吃点什么那",
                     "confidence": 0.96414894
                 },
                 {
                     "transcript": "今天天气很好今天的天气很不错晚上吃点什么那",
                     "confidence": 0.93275815
                 }
             ]
         }
     ]
 }
 
 */

///MARK:- 获取相似度最高的一句
- (void)translateBestConfidenceContent:(void(^)(NSString *content))callBack{
    [self translateContentList:^(NSString *obj) {
			NSDictionary *objDic =  [NSJSONSerialization JSONObjectWithData:[obj dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        NSDictionary *arrDic = [objDic[@"results"] firstObject];
        NSArray *contentList = arrDic[@"alternatives"];
//			NSArray *sortArray = [contentList sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
//				return [obj1[@"confidence"] floatValue] <  [obj2[@"confidence"] floatValue];
//			}];
        !callBack? : callBack(contentList.firstObject[@"transcript"]);
    }];
}

///MARK:- 获取识别的翻译句子列表
- (void)translateContentList:(void(^)(id obj))callBack{
    NSString *service = @"https://speech.googleapis.com/v1/speech:recognize";
    service = [service stringByAppendingString:@"?key="];
    service = [service stringByAppendingString:API_KEY];

    NSData *audioData = [NSData dataWithContentsOfFile:[self soundFilePath]];
    NSDictionary *configRequest = @{@"encoding":@"LINEAR16",
                                    @"sampleRateHertz":@(SAMPLE_RATE),
                                    @"languageCode": self.recordCode,
                                    @"maxAlternatives":@30};
    NSDictionary *audioRequest = @{@"content": [audioData base64EncodedStringWithOptions:0]};
    NSDictionary *requestDictionary = @{@"config": configRequest,
                                        @"audio": audioRequest};
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&error];
    
    NSString *path = service;
    NSURL *URL = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    // if your API key has a bundle ID restriction, specify the bundle ID like this:
    [request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
    NSString *contentType = @"application/json";
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:@"POST"];
    
    NSURLSessionTask *task =
    [[NSURLSession sharedSession]
     dataTaskWithRequest:request
     completionHandler:
     ^(NSData *data, NSURLResponse *response, NSError *error) {
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            NSLog(@"RESULT: %@ ", stringResult);
                            !callBack? : callBack(stringResult);
                        });
     }];
    [task resume];
}

/**
 MARK:- 文本互转
 {
     "data": {
         "translations": [
             {
             "translatedText": "나는 중국인이다.",
             "detectedSourceLanguage": "zh-CN"
             }
         ]
     }
 }

 @param text 文本
 @param targetCode 翻译的对应语言代码
 @param callBack 回调结果字符串
 */
- (void)translateOriginText:(NSString *)text
								 targetCode:(NSString *)targetCode
									 callBack:(void(^)(NSString *objStr))callBack{
	NSString *urlStr = [NSString stringWithFormat:@"https://translation.googleapis.com/language/translate/v2?key=%@",API_KEY];
	NSURL *URL = [NSURL URLWithString: urlStr];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
	NSString *contentType = @"application/json";
	[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
	NSDictionary *requestDictionary = @{  @"q" : text, @"target" : targetCode };
	NSError *error;
	NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&error];
	[request setHTTPBody:requestData];
	[request setHTTPMethod:@"POST"];
	NSURLSessionTask *task =
	[[NSURLSession sharedSession]
	 dataTaskWithRequest:request
	 completionHandler:
	 ^(NSData *data, NSURLResponse *response, NSError *error) {
		 dispatch_async(dispatch_get_main_queue(),
										^{
         NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSArray *results = dataDic[@"data"][@"translations"];
        NSString *translatedText = results.firstObject[@"translatedText"];
         NSLog(@"RESULT: %@ ", dataDic);
        !callBack? : callBack(translatedText);
     });
  }];
	[task resume];
}


///MARK:- 文本 转 语音在线合成
- (void)playAudioWithTranslateWithTextContent:(NSString *)text{
//    http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1&total=1&idx=1&textlen=6&q=陈良良是傻逼&tl=zh-cn
    NSString *baseUrl = @"http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1";
    NSCharacterSet *encodeUrlSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodeContent = [text stringByAddingPercentEncodingWithAllowedCharacters:encodeUrlSet];
    NSString *urlStr = [NSString stringWithFormat:@"%@&total=1&idx=1&textlen=%ld&q=%@&tl=%@",baseUrl,text.length,encodeContent,self.playCode];
    NSURL *url = [NSURL URLWithString: urlStr];
    [self.audioPlayer setUrl: url];

    [self.audioPlayer setOnFailure:^(FSAudioStreamError error, NSString *errorDescription) {
        NSLog(@"合成语音播放出错: -- \t%@\n",errorDescription);
    }];
    
    [self.audioPlayer setOnCompletion:^{
        NSLog(@"播放完成!");
    }];
    
    [self.audioPlayer setOnStateChange:^(FSAudioStreamState state) {
        NSLog(@"FSAudioStreamState播放状态枚举值: %ld ",state);
    }];
    
    [self.audioPlayer play];
}

@end

@implementation NSString(WGBExtra)
	///MARK- google对应的语言编码
- (NSString *)googleLanguageCode{
	NSString *code = @"zh-cn";
	WGBGoogleLanguageType type = [self integerValue];
	switch (type) {
		case WGBGoogleLanguageTypeChinese:
			code = @"zh-cn";
			break;
		case WGBGoogleLanguageTypeEnglish:
			code = @"en";
			break;
		case WGBGoogleLanguageTypeJapanese:
			code = @"ja";
			break;
		case WGBGoogleLanguageTypeKorea:
			code = @"ko";
			break;
		case WGBGoogleLanguageTypeSpain:
			code = @"es";
			break;
		case WGBGoogleLanguageTypeRussian:
			code = @"ru";
			break;
		default:
			break;
	}
	return code;
}

	///MARK- google对应的语言名称
- (NSString *)googleLanguageName{
	NSString *name = @"中文";
	WGBGoogleLanguageType type = [self integerValue];
	switch (type) {
		case WGBGoogleLanguageTypeChinese:
			name = @"中文";
			break;
		case WGBGoogleLanguageTypeEnglish:
			name = @"English";
			break;
		case WGBGoogleLanguageTypeJapanese:
			name = @"日语";
			break;
		case WGBGoogleLanguageTypeKorea:
			name = @"韩语";
			break;
		case WGBGoogleLanguageTypeSpain:
			name = @"西班牙语";
			break;
		case WGBGoogleLanguageTypeRussian:
			name = @"俄罗斯语";
			break;
		default:
			break;
	}
	return name;
}
@end
