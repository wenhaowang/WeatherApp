//
//  WXClient.m
//  SimpleWeather
//
//  Created by Duke on 10/27/15.
//  Copyright © 2015 DU. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForecast.h"
#import "WXHourlyForecast.h"


@interface WXClient()

@property(nonatomic,strong)NSURLSession *session;

@end

@implementation WXClient

-(id)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url {
    //1. 返回信号. 直到这个信号被订阅才会执行
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //2. 创建一个NSURLSessionDataTask（在iOS7中加入）从URL取数据。你会在以后添加的数据解析。
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            //TODO: handle retrevied data
            if (!error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (!jsonError) {
                    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"\n\nFetching : %@ ===> %@",url.absoluteString,jsonString);
                    //a.当JSON数据存在并且没有错误，发送给订阅者序列化后的JSON数组或字典。
                    [subscriber sendNext:json];
                }
                else {
                    //b.在任一情况下如果有一个错误，通知订阅者。
                    [subscriber sendError:jsonError];
                }
            }
            else {
                //b.在任一情况下如果有一个错误，通知订阅者。
                [subscriber sendError:error];
            }
            //c.无论该请求成功还是失败，通知订阅者请求已经完成。
            [subscriber sendCompleted];
        }];
        //3. 一旦订阅了信号, 启动网络请求
        [dataTask resume];
        //4. 创建并返回RACDisposable对象，它处理当信号摧毁时的清理工作。
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        //5. 增加了一个“side effect”，以记录发生的任何错误。side effect不订阅信号，相反，他们返回被连接到方法链的信号。你只需添加一个side effect来记录错误。
        NSLog(@"%@",error);
    }];
}

/*
 By geographic coordinates
 API call:
 
 api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}
 Parameters:
 
 lat, lon coordinates of the location of your interest
 Examples of API calls:
 
 api.openweathermap.org/data/2.5/weather?lat=35&lon=139
 
 API respond:
 
 {"coord":{"lon":139,"lat":35},
 "sys":{"country":"JP","sunrise":1369769524,"sunset":1369821049},
 "weather":[{"id":804,"main":"clouds","description":"overcast clouds","icon":"04n"}],
 "main":{"temp":289.5,"humidity":89,"pressure":1013,"temp_min":287.04,"temp_max":292.04},
 "wind":{"speed":7.31,"deg":187.002},
 "rain":{"3h":0},
 "clouds":{"all":92},
 "dt":1369824698,
 "id":1851632,
 "name":"Shuzenji",
 "cod":200}
*/

//获取当前天气状况
- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=%@",coordinate.latitude,coordinate.longitude,apikey];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
    }];
}

//获取逐时预报
-(RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&appid=%@",coordinate.latitude,coordinate.longitude,apikey];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        return [MTLJSONAdapter modelOfClass:[WXHourlyForecast class] fromJSONDictionary:json error:nil];
    }];
}

//获取每日预报
-(RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&appid=%@&cnt=10",coordinate.latitude,coordinate.longitude,apikey];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        //        WXDailyForecast *forecast = [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:json error:nil];
        return [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:json error:nil];
    }];
}

@end
