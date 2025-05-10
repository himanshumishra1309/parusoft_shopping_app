



const asyncHandler = (requestHandler) => {
    return (req,res,next) => {
    Promise.resolve(requestHandler(req,res,next)).catch((err) => next(err))
}}

export default asyncHandler



//step by step how higher order functions are formed
//where yu take a function as a parameter and pass it another function
// const asyncHandler = () => {}
// const asyncHandler = (function) => {}
// const asyncHandler = (function) => {() => {}}
// //we just simply it by removing curly braces

// const asyncHandler = (function) => async () => {}

// const asyncHandler = (fn) => async (req,res,next) => {
//     try {
//         await fn(req,res,next)
//     } catch (error) {
//         res.status(err.code || 500).json({
//             success: false,
//             message: err.message
//         })
//     }
// }




