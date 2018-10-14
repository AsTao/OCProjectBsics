//
//  HttpClient.m
//  AiCommunity
//
//  Created by Tao on 2018/4/12.
//  Copyright © 2018年 NorthStar. All rights reserved.
//

#import "HttpClient.h"
#import "AppConfig.h"
#import "HttpBaseModel.h"
#import "HttpToastView.h"
#import "BaseAppDelegate.h"
#import "AnySafeValue+Additions.h"

@import AFNetworking;
@import YYModel;


@interface HttpClient()

@end

@implementation HttpClient

- (instancetype)initWithHandel:(id<HttpResponseHandle>)handel
{
    self = [super init];
    if (self) {
        _responseHandle = handel;
    }
    return self;
}

- (void)post:(NSString *)url parameters:(NSDictionary<NSString *,id> *)parameters{
    if (AppConfig.shared.server_url.length == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
                [self.responseHandle didFail:parameters errCode:1003 errInfo:@"server_url is empty"];
            }
        });
        return;
    }
    if (AppConfig.shared.reachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
        if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
            [self.responseHandle didFail:parameters errCode:-1 errInfo:@"Network is not reachable"];
        }
        return;
    }
    
    self.cuurentRequestUrl = url;
    self.cuurentRequestParameters = [self sign:parameters];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = AppConfig.shared.responseSerializer;
    [manager.requestSerializer setTimeoutInterval:30.f];
    
    __weak typeof(self) weakSelf = self;
    NSString *urlString;
    if (_special_server_url.length > 0) {
        urlString = [NSString stringWithFormat:@"%@%@",AppConfig.shared.server_url,url];
    }else{
        urlString = [AppConfig assembleServerUrl:url]
    }
    [manager POST:urlString parameters:self.cuurentRequestParameters progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        HttpBaseModel *model = [HttpBaseModel yy_modelWithJSON:responseObject];
        weakSelf.baseModel = model;
        if (model.success) {
            if ([self.responseHandle respondsToSelector:@selector(willSuccess:)]) {
                [self.responseHandle willSuccess:model.d];
            }
            if ([self.responseHandle respondsToSelector:@selector(didSuccess:)]) {
                [self.responseHandle didSuccess:model.d];
            }
        }else{
            if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
                [self.responseHandle didFail:parameters errCode:model.c errInfo:model.m];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
        NSString *desc = @"";
        if (data) {
            desc = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
            [self.responseHandle didFail:parameters errCode:error.code errInfo:desc];
        }
    }];
}

- (NSDictionary *)sign:(NSDictionary *)parameters{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (AppConfig.shared.sign) {
        [dic setValuesForKeysWithDictionary:AppConfig.shared.sign];
    }
    return dic;
}



- (void)upload:(NSString *)url image:(UIImage *)image parameters:(NSDictionary *)parameters{
    if (AppConfig.shared.reachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
        if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
            [self.responseHandle didFail:@{} errCode:-1 errInfo:@"Network is not reachable"];
        }
        return;
    }
    
    self.cuurentRequestUrl = url;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg", @"image/png", @"application/octet-stream", @"text/json", nil];
    [manager.requestSerializer setTimeoutInterval:30.f];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.2);
    __weak typeof(self) weakSelf = self;
    [manager POST:[AppConfig assembleServerUrl:url] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imageData name:@"fileName" fileName:@"fileName.jpg" mimeType:@"image/jpeg"];//application/octet-stream; charset=UTF-8
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([self.responseHandle respondsToSelector:@selector(willSuccess:)]) {
            [self.responseHandle willSuccess:responseObject];
        }
        if ([weakSelf.responseHandle respondsToSelector:@selector(didSuccess:)]) {
            [weakSelf.responseHandle didSuccess:responseObject];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
            [self.responseHandle didFail:@{} errCode:error.code errInfo:error.description];
        }
    }];
 
}

- (void)download:(NSString *)url{
    if (AppConfig.shared.reachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
        if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
            [self.responseHandle didFail:@{} errCode:-1 errInfo:@"Network is not reachable"];
        }
        return;
    }
    self.cuurentRequestUrl = url;


    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:[AppConfig assembleServerUrl:self.cuurentRequestUrl]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (filePath.absoluteString.length > 0 && error == nil) {
            if ([self.responseHandle respondsToSelector:@selector(didSuccess:)]) {
                [self.responseHandle didSuccess:filePath];
            }
        }else{
            if ([self.responseHandle respondsToSelector:@selector(didFail:errCode:errInfo:)]) {
                [self.responseHandle didFail:@{} errCode:error.code errInfo:error.description];
            }
        }
    }];
    [downloadTask resume];
}

- (void)batchRequests:(NSString *)url parameters:(NSArray<NSDictionary<NSString *,id> *> *)parameters{
    if (AppConfig.shared.reachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
        return;
    }
    
    NSString *urlString = [AppConfig assembleServerUrl:url];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    dispatch_group_async(group, q, ^{
        
        for (NSDictionary<NSString *,id> *param in parameters) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            manager.responseSerializer = AppConfig.shared.responseSerializer;
            [manager.requestSerializer setTimeoutInterval:30.f];
            
            //__weak typeof(self) weakSelf = self;
            [manager POST:urlString parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                HttpBaseModel *model = [HttpBaseModel yy_modelWithJSON:responseObject];
                NSLog(@"code=%@",model.c);
                NSLog(@"message=%@",model.m);
                dispatch_group_leave(group);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
                NSString *desc = @"";
                if (data) {
                    desc = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                NSLog(@"fail=%@",desc);
                dispatch_group_leave(group);
            }];
        }
        
    });
}



@end
