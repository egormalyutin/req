(async function() {
	const greet = await require.async("./greeter/main.js");
	greet("req.js");
}())
