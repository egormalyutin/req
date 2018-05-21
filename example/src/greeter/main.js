const { message } = await require.async("./message");

module.exports = (name) => {
	const ready = document.getElementById("ready");
	ready.innerHTML = message + name;
}