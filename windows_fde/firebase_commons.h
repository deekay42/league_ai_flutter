#pragma once

#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"

	extern ::firebase::App *app;
	extern ::firebase::database::Database *database;


	extern firebase::Future<firebase::auth::User *> user_future;
	extern firebase::auth::User* user;
	extern ::firebase::functions::Functions *functions;
	extern ::firebase::auth::Auth *auth;