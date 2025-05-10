export default class ApiError extends Error {

    constructor(
        statusCode,
        message = "Something went wrong",
        stack = "",
        errors = []
    )
    {
            // to override
            super(message),
            this.statusCode = statusCode,
            // assignment 
            this.data = null,
            // we are handling Api errors and not response therefore no need of sucess flag
            this.success = false,
            this.message = message,
            this.errors = errors

            if(stack){
                this.stack = stack
            } else {
                Error.captureStackTrace(this, this.constructor)
            }

    }
}


