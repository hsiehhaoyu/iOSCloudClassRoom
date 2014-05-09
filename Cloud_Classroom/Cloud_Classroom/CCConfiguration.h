//
//  CCConfiguration.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//
/* 
 * This is used by CCCommunicationHandler and whoever
 * going to set server url and port of the handler
 */

#ifndef Cloud_Classroom_CCConfiguration_h
#define Cloud_Classroom_CCConfiguration_h

//====== SERVER SETTING==========
//(Used by whoever going to set the handler)

#define DEFAULT_SERVER_URL @"54.187.167.5"
#define DEFAULT_SERVER_PORT 4119

//#define SERVER_URL_STRING @"localhost"
//#define SERVER_PORT_NUM 4119

#define ALLOWED_MIN_PORT_NUM 0
#define ALLOWED_MAX_PORT_NUM 65535

//====== S3 Server ==============
#define S3_ACCESS_KEY @"AKIAJQAGTZZGZ6WIE3AQ"
#define S3_SECRET_KEY @"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"
#define BUCKET_NAME @"CloudClassRoom"
//#define IMAGE_CONTENT_TYPE @"image/png"
//#define TEXT_CONTENT_TYPE @"text/txt"

//========== COMMANDS ===========
//(Used by CCComunicationHandler)
//1.	user sign up (create new account) → 先不管
//2.	user log-in (登入)
#define LOGIN_REQ @"LOGIN_REQ"
#define LOGIN_RES @"LOGIN_RES"
//3.	user log-out (使用者登入相關)
#define LOGOUT_REQ @"LOGOUT_REQ"
#define LOGOUT_RES @"LOGOUT_RES"
//4.	create class (create 一個 user cluster, 指定 default instructor)
#define CREATE_CLASS_REQ @"CREATE_CLASS_REQ"
#define CREATE_CLASS_RES @"CREATE_CLASS_RES"
//5.	list class (列出現在 user 可以加入的 class)
#define LIST_CLASS_REQ @"LIST_CLASS_REQ"
#define LIST_CLASS_RES @"LIST_CLASS_RES"
//6.	delete class (消除這個 user cluster)
#define DEL_CLASS_REQ @"DELETE_CLASS_REQ"
#define DEL_CLASS_RES @"DELETE_CLASS_RES"
//7.	join class (讓 user 可以加入這個 cluster, permission control 也在這裡做)
#define JOIN_CLASS_REQ @"JOIN_CLASS_REQ"
#define JOIN_CLASS_RES @"JOIN_CLASS_RES"
//8.	query class info
#define QUERY_CLASS_INFO_REQ @"QUERY_CLASS_INFO_REQ"
#define QUERY_CLASS_INFO_RES @"QUERY_CLASS_INFO_RES"
//9.	leave class (離開這個 cluster)
#define QUIT_CLASS_REQ @"QUIT_CLASS_REQ"
#define QUIT_CLASS_RES @"QUIT_CLASS_RES"
//10.	kick user from class (由 instructor 強迫某個 user 退出)
#define KICK_USER_REQ @"KICK_USER_REQ"
#define KICK_USER_RES @"KICK_USER_RES"
#define KICK_USER_IND @"KICK_USER_IND"
//11.	push content (把 instructor 的 content push 給所有 student)
#define PUSH_CONTENT_REQ @"PUSH_CONTENT_REQ"
#define PUSH_CONTENT_RES @"PUSH_CONTENT_RES"
#define PUSH_CONTENT_NOTIFY @"PUSH_CONTENT_NOTIFY"
#define PUSH_CONTENT_GET_REQ @"PUSH_CONTENT_GET_REQ"
#define PUSH_CONTENT_GET_RES @"PUSH_CONTENT_GET_RES"
//12.	conditional push (client 有 cache 就不要來拿 data) → advance (power consumption 的 optimization)
#define COND_PUSH_CONTENT_REQ @"COND_PUSH_CONTENT_REQ"
#define COND_PUSH_CONTENT_RES @"COND_PUSH_CONTENT_RES"
#define COND_PUSH_CONTENT_GET_NOTIFY @"COND_PUSH_CONTENT_GET_NOTIFY"
//13.	request presenter right (由 instructor 來 approve) → no presenter case allowed
#define GET_PRESENT_TOKEN_REQ @"GET_PRESENT_TOKEN_REQ"
#define CHANGE_PRESENT_TOKEN_REQ @"CHANGE_PRESENT_TOKEN_REQ"
#define CHANGE_PRESENT_TOKEN_RES @"CHANGE_PRESENT_TOKEN_RES"
#define GET_PRESENT_TOKEN_RES @"GET_PRESENT_TOKEN_RES"
#define CHANGE_PRESENT_TOKEN_IND @"CHANGE_PRESENT_TOKEN_IND"
//14.	instructor 暴力取回法 presenter switch (push content 的 user 換人)
#define RETRIEVE_PRESENT_TOKEN_REQ @"RETRIEVE_PRESENT_TOKEN_REQ"
#define RETRIEVE_PRESENT_TOKEN_IND @"RETRIEVE_PRESENT_TOKEN_IND"
#define RETRIEVE_PRESENT_TOKEN_RES @"RETRIEVE_PRESENT_TOKEN_RES"
//15.
#define QUERY_LATEST_CONTENT_REQ @"QUERY_LATEST_CONTENT_REQ"
#define QUERY_LATEST_CONTENT_RES @"QUERY_LATEST_CONTENT_RES"

//================= STATUS ========================
#define INVALID_USER @"INVALID_USER"
#define LOGIN_FAIL @"LOGIN_FAIL"
#define DUPLICATE @"DUPLICATE"
#define LOGGED_IN @"LOGGED_IN"
#define INVALID_COOKIE @"INVALID_COOKIE"
#define LOGOUT_FAIL @"LOGOUT_FAIL"
#define LOGGED_OUT @"LOGGED_OUT"
#define NOT_LOGIN @"NOT_LOGIN"
#define NO_PERMISSION @"NO_PERMISSION"
#define DUPLICATE_NAME @"DUPLICATE_NAME"
#define SUCCESS @"SUCCESS"
#define INVALID_CLASS_ID @"INVALID_CLASS_ID"
#define ALREADY_IN_CLASS @"ALREADY_IN_CLASS"
#define DENIED @"DENIED"
#define NOT_IN_CLASS @"NOT_IN_CLASS"
#define CONTENT_NOT_IN_CLASS @"CONTENT_NOT_IN_CLASS"
#define ALREADY_PRESENTER @"ALREADY_PRESENTER"
#define NO_CONTENT @"NO_CONTENT"

//================ MISC ==========================
//device type
#define IOS @"iOS"
//content type (for our srever, not s3)
#define IMAGE_TYPE @"image"
#define TEXT_TYPE @"text"

//================ NSUserDefault =================
#define SERVER_URL @"SERVER_URL"
#define SERVER_PORT @"SERVER_PORT"

#endif
