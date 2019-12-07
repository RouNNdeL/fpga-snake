function convertColor(c) {
	const r = (c & 0xFF0000) >> 9;
	const g = (c & 0x00FF00) >> 6;
	const b = (c & 0x0000FF) >> 3;

	return (r | g | b).toString(16);
}
