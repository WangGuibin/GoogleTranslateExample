# GoogleTranslateExample
Google Translate Demo  &amp;&amp; google 语音识别/翻译/语音合成 demo

# google语音识别  

1. 到`google`注册相关的`API_KEY`, 地址: `https://cloud.google.com/speech-to-text/docs/samples`
2. 下载demo  `https://github.com/GoogleCloudPlatform/ios-docs-samples/tree/master/speech/Objective-C/Speech-REST-Nonstreaming`
3. 录制语音文件存于沙盒, 上传语音文件到 `https://speech.googleapis.com/v1/speech:recognize?key=xxxxx`



### 核心代码:
```objectivec
  NSString *service = @"https://speech.googleapis.com/v1/speech:recognize";
  service = [service stringByAppendingString:@"?key="];
  service = [service stringByAppendingString:API_KEY];

  NSData *audioData = [NSData dataWithContentsOfFile:[self soundFilePath]];//沙盒里的录音文件 具体看google提供的demo
  NSDictionary *configRequest = @{@"encoding":@"LINEAR16",
                                  @"sampleRateHertz":@(SAMPLE_RATE),
                                  @"languageCode":@"zh-cn",
                                  @"maxAlternatives":@30};
  NSDictionary *audioRequest = @{@"content":[audioData base64EncodedStringWithOptions:0]};
  NSDictionary *requestDictionary = @{@"config":configRequest,
                                      @"audio":audioRequest};
  NSError *error;
  NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                        options:0
                                                          error:&error];

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
                      _textView.text = stringResult;
                      NSLog(@"RESULT: %@ ", stringResult);
                    });
   }];
  [task resume];

```

# google 文本翻译

 文本翻译和语音识别类似,都需要`API_KEY`,同样是POST请求

```objectivec
/**
 MARK:- 文本互转

 @param text 文本
 @param targetCode 翻译的对应语言代码
 @param callBack 回调结果json字符串
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
// q: 原文本  tagret: 目标语言的代码 zh-cn,en-us...等
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
											NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
											NSLog(@"RESULT: %@ ", stringResult);
											!callBack? : callBack(stringResult);
										});
	 }];
	[task resume];
}

```

# google 语音合成 

- 合成是免费的 , 然后是这个接口  `http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1`
-  参数组成
```
//基地址
BASE_URL = @"http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1"

//拼接规则和get请求类似
total   //标准为100个字符为一组 然后total是总共多少组 
idx    //下标,第几组
textlen  //所有文字的计数,就是这个字符串的长度
q     //合成的文字内容,中文的话需要转编码utf-8最为合适
tl  //语言，跟识别的语言一致
```
主要参数介绍: 
`ie`: 输入参数编码 `input-encode` 一般为`utf-8`
`oe`: 输入参数编码 `output-encode` 一般为`utf-8`
`ttsspeed`: 合成的语速
`tl`: 目标语言代码 `target language`
`hl`: 当地语言代码 `home language`


url编码前: 
`http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1&total=1&idx=1&textlen=6&q=某某某是傻逼&tl=zh-cn`
url编码后: 
`http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1&total=1&idx=1&textlen=6&q=%E9%99%88%E8%89%AF%E8%89%AF%E6%98%AF%E5%82%BB%E9%80%BC&tl=zh-cn`

### 核心代码

```
///MARK:- 文本 转 语音在线合成
- (void)synthesisAudioWithTranslateWithText:(NSString *)text{
    NSString *baseUrl = @"http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&ttsspeed=1";
 //url编码
    NSCharacterSet *encodeUrlSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodeContent = [text stringByAddingPercentEncodingWithAllowedCharacters:encodeUrlSet];
    NSString *urlStr = [NSString stringWithFormat:@"%@&total=1&idx=1&textlen=%ld&q=%@&tl=%@",baseUrl,text.length,encodeContent,self.targetCode];
    NSURL *url = [NSURL URLWithString: urlStr];
      //播放拼接的链接  因为合成的链接是流媒体音频,采用的是`pod 'FreeStreamer' `
	

}
```

### 主流的几种语言的代码对照表:
|国家|languageCode|
|:---:|:---:|
|🇨🇳中文(简体)|`zh-cn`|
|🇨🇳中文(繁体)|`zh-tw`|
|🇺🇸英文|`en`|
|🇯🇵日语|`ja`|
|🇰🇷韩语|`ko`|
|🇷🇺俄语|`ru`|
|🇪🇸西班牙语|`es`|
|🇫🇷法语|`fr`|
|🇩🇪德语|`de`|