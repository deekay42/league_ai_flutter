#pragma once

#include ".\common.h"

#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"

extern ::firebase::App *app;
extern ::firebase::database::Database *database;

extern firebase::Future<firebase::auth::User *> user_future;
extern firebase::auth::User *user;
extern ::firebase::functions::Functions *functions;
extern ::firebase::auth::Auth *auth;
extern std::string myuid;
extern std::string mysecret;


// Wait for a Future to be completed. If the Future returns an error, it will
// be logged.
void WaitForCompletion(const firebase::FutureBase &future, const char *name);

firebase::Variant callFBFunctionSync(
    const char *functionName,
    std::map<std::string, firebase::Variant> *data = nullptr);


bool authenticate(std::string uid, std::string secret);