//
//  WGBGoogleSpeechManager.h
//  Created by CoderWGB on 2018/8/3.
//  Copyright © 2018年 DoubleMonkeyTechnology. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,WGBGoogleLanguageType)
{
	WGBGoogleLanguageTypeChinese = 0, //中文
	WGBGoogleLanguageTypeEnglish ,//英语
	WGBGoogleLanguageTypeJapanese, //日语
	WGBGoogleLanguageTypeKorea, //韩语
	WGBGoogleLanguageTypeSpain , //西班牙语
	WGBGoogleLanguageTypeRussian, //俄罗斯语
};


@interface WGBGoogleSpeechManager : NSObject

///MARK:- 做成单例
+ (instancetype)shareDefault;

///MARK:- 设置录制语言
- (void)setRecordLanguageCode:(WGBGoogleLanguageType)langCode;
///MARK:- 设置播放语言
- (void)setPlayLanguageCode:(WGBGoogleLanguageType)langCode;

///MARK:- 开始录音
- (void)startRecordAction;
///MARK:- 停止录音
- (void)stopRecordAction;

///MARK:- 获取语音识别的结果  调用时机是录制停止的时候
@property (nonatomic,copy) void(^getSpeechRecognizeContentBlock)(NSString *content);

///MARK:- 获取相似度最高的一句  语音转换的文本字符串
- (void)translateBestConfidenceContent:(void(^)(NSString *content))callBack;

///MARK:- 获取识别的翻译句子列表 json
- (void)translateContentList:(void(^)(id obj))callBack;


	///MARK:- 文本互转 返回翻译结果字符串
- (void)translateOriginText:(NSString *)text
								 targetCode:(NSString *)targetCode
									 callBack:(void(^)(NSString *objStr))callBack ;

///MARK:- 文本 转 语音在线合成  合成并播放
- (void)playAudioWithTranslateWithTextContent:(NSString *)text;

@end

@interface NSString (WGBExtra)
	///MARK- google对应的语言编码
- (NSString *)googleLanguageCode;
	///MARK- google对应的语言名称
- (NSString *)googleLanguageName;
@end

