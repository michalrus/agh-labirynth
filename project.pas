program project;
{$APPTYPE GUI}

uses dos, crt, gl, glu, glut, math, sysutils;

const
	MAZE_TOP = 1;
	MAZE_RIG = 2;
	MAZE_BOT = 4;
	MAZE_LEF = 8;
	MAZE_EXI = 16;
	MAZE_ENT = 32;
	MAZE_VIS = 64;

	MAZE_R = 0.9;
	MAZE_G = 0.9;
	MAZE_B = 0.9;
	MAZE_BALL = 0.3;
	MAZE_WALL = 0.3;
	MAZE_LI_PHI = -45;
	MAZE_LI_THETA = 30;

var
	t0, t1, t2, dt: GLfloat;
	maze: array of array of byte;
	mazeW, mazeH: longint;

	cSpeed, cPosX, cPosZ,
	pPosX, pPosZ, npPosX, npPosZ, camPhi, camTheta,
	camR, camX, camY, camZ: GLfloat;
	liXYZ: array[0..3] of GLfloat;
	kSh, kUp, kDn, kRg, kLf, kE, kD, kF, kS, kA, kZ: boolean;

	solveQueue: array of integer;
	solveQueuePos: integer;

	allBlocked: boolean;

	menu: integer;
	menuW, menuH: integer;
	menuFile: string;

procedure solveMaze;
var
	i, j, k: integer;
	curStack, nei: array of integer;
begin
	setlength(curStack, 0);
	setlength(solveQueue, 0);
	solveQueuePos := 0;

	i := trunc(cPosZ);
	j := trunc(cPosX);

	while (true) do begin
		setlength(solveQueue, length(solveQueue) + 2);
		solveQueue[length(solveQueue) - 2] := i;
		solveQueue[length(solveQueue) - 1] := j;
		maze[i, j] := maze[i, j] or MAZE_VIS;

		if (maze[i, j] and MAZE_EXI <> 0) then
			// solution found
			break;

		setlength(nei, 0);
		if (i > 0) and (maze[i, j] and MAZE_TOP = 0) and (maze[i - 1, j] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 0;
		end;
		if (i < mazeH - 1) and (maze[i, j] and MAZE_BOT = 0) and (maze[i + 1, j] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 2;
		end;
		if (j > 0) and (maze[i, j] and MAZE_LEF = 0) and (maze[i, j - 1] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 3;
		end;
		if (j < mazeW - 1) and (maze[i, j] and MAZE_RIG = 0) and (maze[i, j + 1] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 1;
		end;

		if (length(nei) = 0) then begin
			if (length(curStack) = 0) then
				// no solution possible...
				break;
			i := curStack[length(curStack) - 2];
			j := curStack[length(curStack) - 1];
			setlength(curStack, length(curStack) - 2);
		end else begin
			setlength(curStack, length(curStack) + 2);
			curStack[length(curStack) - 2] := i;
			curStack[length(curStack) - 1] := j;

			k := random(length(nei));
			if (nei[k] = 0) then begin
				i := i - 1;
			end else if (nei[k] = 1) then begin
				j := j + 1;
			end else if (nei[k] = 2) then begin
				i := i + 1;
			end else if (nei[k] = 3) then begin
				j := j - 1;
			end;
		end;
	end;
end;

procedure dfsMaze (n, m: integer);
var
	dfsMazeRStack, nei: array of integer;
	i, j, k, l: integer;
begin
	mazeH := n;
	mazeW := m;

	pPosX := m - 1 + 0.5;
	pPosZ := n - 1 + 0.5;
	cPosX := m - 1;
	cPosZ := m - 1;

	setlength(maze, n);
	for i := 0 to n - 1 do begin
		setlength(maze[i], m);
		for j := 0 to m - 1 do
			maze[i, j] := MAZE_TOP or MAZE_RIG or MAZE_BOT
				or MAZE_LEF;
	end;

	setlength(dfsMazeRStack, 0);

	i := random(n);
	j := random(m);
	while (true) do begin
		maze[i, j] := maze[i, j] or MAZE_VIS;

		setlength(nei, 0);
		if (i > 0) and (maze[i - 1, j] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 0;
		end;
		if (i < mazeH - 1) and (maze[i + 1, j] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 2;
		end;
		if (j > 0) and (maze[i, j - 1] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 3;
		end;
		if (j < mazeW - 1) and (maze[i, j + 1] and MAZE_VIS = 0) then begin
			setlength(nei, length(nei) + 1);
			nei[length(nei) - 1] := 1;
		end;

		if (length(nei) = 0) then begin
			if (length(dfsMazeRStack) = 0) then
				break;
			i := dfsMazeRStack[length(dfsMazeRStack) - 2];
			j := dfsMazeRStack[length(dfsMazeRStack) - 1];
			setlength(dfsMazeRStack, length(dfsMazeRStack) - 2);
		end else begin
			setlength(dfsMazeRStack, length(dfsMazeRStack) + 2);
			dfsMazeRStack[length(dfsMazeRStack) - 2] := i;
			dfsMazeRStack[length(dfsMazeRStack) - 1] := j;

			k := random(length(nei));
			if (nei[k] = 0) then begin
				maze[i, j] := maze[i, j] and not MAZE_TOP;
				maze[i - 1, j] := maze[i - 1, j] and not MAZE_BOT;
				i := i - 1;
			end else if (nei[k] = 1) then begin
				maze[i, j] := maze[i, j] and not MAZE_RIG;
				maze[i, j + 1] := maze[i, j + 1] and not MAZE_LEF;
				j := j + 1;
			end else if (nei[k] = 2) then begin
				maze[i, j] := maze[i, j] and not MAZE_BOT;
				maze[i + 1, j] := maze[i + 1, j] and not MAZE_TOP;
				i := i + 1;
			end else if (nei[k] = 3) then begin
				maze[i, j] := maze[i, j] and not MAZE_LEF;
				maze[i, j - 1] := maze[i, j - 1] and not MAZE_RIG;
				j := j - 1;
			end;
		end;
	end;

	for i := 0 to n - 1 do
		for j := 0 to m - 1 do
			maze[i, j] := ((maze[i, j] and not MAZE_ENT) and not MAZE_EXI) and not MAZE_VIS;

{
	maze[0, 0] := maze[0, 0] or MAZE_EXI;
	maze[n - 1, m - 1] := maze[n - 1, m - 1] or MAZE_ENT;
}

	k := random(2 * (n - 1) + 2 * (m - 1));
	if (k < m - 1) then begin
		i := 0;
		j := k;
//		k := mazeH - 1;
	//	l := mazeW - 1 - j;
	end else if (k < (m - 1) + (n - 1)) then begin
		i := k - (m - 1);
		j := mazeW - 1;
//		k := mazeH - 1 - i;
	//	l := 0;
	end else if (k < 2 * (m - 1) + (n - 1)) then begin
		i := mazeH - 1;
		j := k - (m - 1) - (n - 1);
//		k := 0;
	//	l := mazeW - 1 - j;
	end else begin
		i := k - 2 * (m - 1) - (n - 1);
		j := 0;
	end;

	k := mazeH - 1 - i;
	l := mazeW - 1 - j;

	maze[i, j] := maze[i, j] or MAZE_EXI;
	maze[k, l] := maze[k, l] or MAZE_ENT;
	pPosX := l + 0.5;
	pPosZ := k + 0.5;
	cPosX := pPosX;
	cPosZ := pPosZ;
end;

procedure saveMaze (path: string);
var
	f: file of char;
	i, j: integer;
begin
	writeln('helou...');
	assign(f, path);
	rewrite(f);
	seek(f, 0);

	for i := 0 to mazeH - 1 do begin
		for j := 0 to mazeW - 1 do begin
			if (i < mazeH - 1) and (maze[i, j] and MAZE_BOT <> 0) then begin
				if (maze[i, j] and MAZE_ENT <> 0) then begin
					write(f, 'L');
				end else if (maze[i, j] and MAZE_EXI <> 0) then begin
					write(f, 'E');
				end else begin
					write(f, '_');
				end;
			end else begin
				if (maze[i, j] and MAZE_ENT <> 0) then begin
					write(f, 'l');
				end else if (maze[i, j] and MAZE_EXI <> 0) then begin
					write(f, 'e');
				end else begin
					write(f, ' ');
				end;
			end;
			if (j < mazeW - 1) then begin
				if (maze[i, j] and MAZE_RIG <> 0) then begin
					write(f, '|');
				end else begin
					write(f, ' ');
				end;
			end;
		end;
		write(f, chr(13));
		write(f, chr(10));
	end;

	close(f);
end;

procedure readMaze (path: string);
var
	f: text;
	s: string;
	first: boolean;
	i: longint;
	fl: byte;
begin
	assign(f, path);
	reset(f);

	mazeH := 0;
	first := true;
	while not eof(f) do begin
		readln(f, s);
		s := '|' + s;
		if (first) then begin
			mazeW := length(s) div 2;
			first := false;
		end;
		mazeH := mazeH + 1;

		setlength(maze, mazeH);
		setlength(maze[mazeH - 1], mazeW);

		for i := 0 to (mazeW - 1) do begin
			fl := 0;
			if (s[1 + 2 * i] = '|') then begin
				fl := fl or MAZE_LEF;
				if (i > 0) then begin
					maze[mazeH - 1, i - 1] :=
						maze[mazeH - 1, i - 1] or MAZE_RIG;
				end;
			end;
			if (s[2 + 2 * i] = '_') or (s[2 + 2 * i] = 'E') or (s[2 + 2 * i] = 'L') then
				fl := fl or MAZE_BOT;
			if (mazeH = 1) or (maze[mazeH - 2, i] and MAZE_BOT <> 0) then
				fl := fl or MAZE_TOP;
			if (i = mazeW - 1) then
				fl := fl or MAZE_RIG;
			if (s[2 + 2 * i] = 'E') or (s[2 + 2 * i] = 'e') then
				fl := fl or MAZE_EXI;
			if (s[2 + 2 * i] = 'L') or (s[2 + 2 * i] = 'l') then begin
				fl := fl or MAZE_ENT;
				pPosX := i + 0.5;
				pPosZ := mazeH - 1 + 0.5;
				cPosX := pPosX;
				cPosZ := pPosZ;
			end;
			maze[mazeH - 1, i] := fl;
		end;
	end;
	close(f);

	for i := 0 to (mazeW - 1) do
		maze[mazeH - 1, i] := maze[mazeH - 1, i] or MAZE_BOT;

{
	for i := 0 to (mazeH - 1) do begin
		for j := 0 to (mazeW - 1) do
			write(maze[i, j]:4);
		writeln;
	end;
}
end;

procedure drawText (x, y: GLfloat; s: string);
var
	i: LongInt;
begin
	glPushMatrix;
		glLoadIdentity;
		glTranslatef(0.0, 0.0, -20.0);
		glRasterPos2f(x, y);
		for i := 1 to length(s) do
			glutBitmapCharacter(GLUT_BITMAP_9_BY_15, LongInt(s[i]));
	glPopMatrix;
end;

procedure drawRegularPolygon (n: integer; r: GLfloat);
var
	i: integer;
	phi : GLfloat;
begin
	glBegin(GL_POLYGON);
		glNormal3f(0, 0, 1);
		for i := 0 to (n - 1) do begin
			phi := 2 * pi / n * i;
			glVertex3f(r * cos(phi), r * sin(phi), 0);
		end;
	glEnd;
end;

procedure drawCuboid (x, y, z, lx, ly, lz: GLfloat);
var
	ldx, ldy, ldz: GLfloat;
begin
	ldx := lx / 2.0;
	ldy := ly / 2.0;
	ldz := lz / 2.0;

	glBegin(GL_QUADS);
		glNormal3f(0, 0, 1);
		glVertex3f(x - ldx, y - ldy, z + ldz);
		glVertex3f(x - ldx, y + ldy, z + ldz);
		glVertex3f(x + ldx, y + ldy, z + ldz);
		glVertex3f(x + ldx, y - ldy, z + ldz);
	glEnd;

	glBegin(GL_QUADS);
		glNormal3f(0, 0, -1);
		glVertex3f(x - ldx, y - ldy, z - ldz);
		glVertex3f(x - ldx, y + ldy, z - ldz);
		glVertex3f(x + ldx, y + ldy, z - ldz);
		glVertex3f(x + ldx, y - ldy, z - ldz);
	glEnd;

	glBegin(GL_QUADS);
		glNormal3f(-1, 0, 0);
		glVertex3f(x - ldx, y - ldy, z + ldz);
		glVertex3f(x - ldx, y + ldy, z + ldz);
		glVertex3f(x - ldx, y + ldy, z - ldz);
		glVertex3f(x - ldx, y - ldy, z - ldz);
	glEnd;

	glBegin(GL_QUADS);
		glNormal3f(1, 0, 0);
		glVertex3f(x + ldx, y - ldy, z + ldz);
		glVertex3f(x + ldx, y + ldy, z + ldz);
		glVertex3f(x + ldx, y + ldy, z - ldz);
		glVertex3f(x + ldx, y - ldy, z - ldz);
	glEnd;

	glBegin(GL_QUADS);
		glNormal3f(0, 1, 0);
		glVertex3f(x - ldx, y + ldy, z + ldz);
		glVertex3f(x + ldx, y + ldy, z + ldz);
		glVertex3f(x + ldx, y + ldy, z - ldz);
		glVertex3f(x - ldx, y + ldy, z - ldz);
	glEnd;

	glBegin(GL_QUADS);
		glNormal3f(0, -1, 0);
		glVertex3f(x - ldx, y - ldy, z + ldz);
		glVertex3f(x + ldx, y - ldy, z + ldz);
		glVertex3f(x + ldx, y - ldy, z - ldz);
		glVertex3f(x - ldx, y - ldy, z - ldz);
	glEnd;
end;

procedure drawWall (x1, z1, x2, z2: GLfloat);
const
	w = 0.05;
begin
	glPushMatrix;
		glTranslatef((x1 + x2) / 2, MAZE_WALL / 2, (z1 + z2) / 2);
		glRotatef(arctan2((-z2) - (-z1), x2 - x1) * 180 / pi, 0, 1, 0);
		drawCuboid(0, 0, 0, w + sqrt((x1 - x2)*(x1 -x2) + (z1 - z2)*(z1 - z2)), MAZE_WALL, w);
	glPopMatrix;
end;

procedure drawMaze;
var
	i, j: integer;
begin
	glColor4f(MAZE_R, MAZE_G, MAZE_B, 1);
	glPushMatrix;
		glTranslatef(-mazeW / 2, 0, -mazeH / 2);
		drawWall(0, 0, mazeW, 0);
		drawWall(mazeW, 0, mazeW, mazeH);
		for i := 0 to (mazeH - 1) do begin
			glPushMatrix;
				for j := 0 to (mazeW - 1) do begin
					if (maze[i, j] and MAZE_LEF <> 0) then
						drawWall(0, 0, 0, 1);
					if (maze[i, j] and MAZE_BOT <> 0) then
						drawWall(0, 1, 1, 1);
					if (maze[i, j] and MAZE_EXI <> 0) then begin
						glPushMatrix;
							glColor4f(0, 0.5, 0, 1);
							glTranslatef(0.5, 0, 0.5);
							glRotatef(90, -1, 0, 0);
							drawRegularPolygon(20, 0.3);
							glColor4f(MAZE_R, MAZE_G, MAZE_B, 1);
						glPopMatrix;
					end;
					glTranslatef(1, 0, 0);
				end;
			glPopMatrix;
			glTranslatef(0, 0, 1);
		end;
	glPopMatrix;
end;

procedure userInput;
var
	tmp: GLfloat;
	dx: GLfloat;
	dArr: integer;
	kArr: array[0..7] of boolean;
begin
	{ arrows' real directions changed by cam rotation }
	kArr[0] := kUp; kArr[1] := kRg; kArr[2] := kDn; kArr[3] := kLf;
	kArr[4] := kUp; kArr[5] := kRg; kArr[6] := kDn; kArr[7] := kLf;
	dArr := trunc((round(-camPhi + 135) mod 360 + 360) mod 360 / 90);

	{ new player positions }
	npPosX := pPosX;
	npPosZ := pPosZ;

	dx := dt * 3;

	if (not allBlocked) then begin
		if (kSh) then { kSh --> acceleration }
			dx := dx * 3;
		if (kArr[0 + dArr]) then
			npPosZ := npPosZ - dx;
		if (kArr[2 + dArr]) then
			npPosZ := npPosZ + dx;
		if (kArr[1 + dArr]) then
			npPosX := npPosX + dx;
		if (kArr[3 + dArr]) then
			npPosX := npPosX - dx;
	end;

	{ rotate cam & light }
	if (kE) and (camTheta < 89) then
		camTheta := camTheta + 60 * dt;
	if (kD) and (camTheta > 1) then
		camTheta := camTheta - 60 * dt;
	if (kS) then
		camPhi := camPhi + 60 * dt;
	if (kF) then
		camPhi := camPhi - 60 * dt;
	if (kA) then
		camR := camR - 9 * dt;
	if (kZ) then
		camR := camR + 9 * dt;

	tmp := cos((camTheta + MAZE_LI_THETA) * pi / 180);
	liXYZ[0] := camR * cos((camPhi + MAZE_LI_PHI) * pi / 180) * tmp;
	liXYZ[1] := camR * sin((camTheta + MAZE_LI_THETA) * pi / 180);
	liXYZ[2] := camR * sin((camPhi + MAZE_LI_PHI) * pi / 180) * tmp;
	liXYZ[3] := 1.0;

	tmp := cos(camTheta * pi / 180);
	camX := camR * cos(camPhi * pi / 180) * tmp;
	camY := camR * sin(camTheta * pi / 180);
	camZ := camR * sin(camPhi * pi / 180) * tmp;
end;

procedure moveEnemy;
var
	dx: GLfloat;
begin
	if (allBlocked) or (length(solveQueue) < solveQueuePos + 4) then begin
		allBlocked := true;
		exit;
	end;

	if (t1 < 1.5) then begin
		t1 := t1 + dt;
		exit;
	end;
	
	dx := dt * cSpeed;

	if (solveQueue[solveQueuePos] = solveQueue[solveQueuePos + 2])
		and (solveQueue[solveQueuePos + 1] < solveQueue[solveQueuePos + 3]) then
		cPosX := cPosX + dx;
	if (solveQueue[solveQueuePos] = solveQueue[solveQueuePos + 2])
		and (solveQueue[solveQueuePos + 1] > solveQueue[solveQueuePos + 3]) then
		cPosX := cPosX - dx;
	if (solveQueue[solveQueuePos + 1] = solveQueue[solveQueuePos + 3])
		and (solveQueue[solveQueuePos] > solveQueue[solveQueuePos + 2]) then
		cPosZ := cPosZ - dx;
	if (solveQueue[solveQueuePos + 1] = solveQueue[solveQueuePos + 3])
		and (solveQueue[solveQueuePos] < solveQueue[solveQueuePos + 2]) then
		cPosZ := cPosZ + dx;

	if (abs(cPosZ - (solveQueue[solveQueuePos + 2] + 0.5)) <= dx)
		and (abs(cPosX - (solveQueue[solveQueuePos + 3] + 0.5)) <= dx) then begin
		cPosX := solveQueue[solveQueuePos + 3] + 0.5;
		cPosZ := solveQueue[solveQueuePos + 2] + 0.5;
		solveQueuePos := solveQueuePos + 2;
	end;
end;

procedure resolveCollisions;
var
	i, j: integer;
	d: GLfloat;
begin
	{ old position in maze }
	i := round(pPosZ - 0.5);
	j := round(pPosX - 0.5);

	{ win check }
	if (maze[i, j] and MAZE_EXI <> 0) and (abs(0.5 - (pPosZ - i)) < 0.2) and (abs(0.5 - (pPosX - j)) < 0.2) then begin
		allBlocked := true;
		pPosZ := i + 0.5;
		pPosX := j + 0.5;
		exit;
	end;

	d := MAZE_WALL * 0.75;

	{ *really primitive* collision checks }
	if ((maze[i, j] and MAZE_TOP <> 0) and (npPosZ - i < d)) then
		npPosZ := d + i;
	if ((maze[i, j] and MAZE_BOT <> 0) and (npPosZ - i > (1 - d))) then
		npPosZ := (1 - d) + i;
	if ((maze[i, j] and MAZE_RIG <> 0) and (npPosX - j > (1 - d))) then
		npPosX := (1 - d) + j;
	if ((maze[i, j] and MAZE_LEF <> 0) and (npPosX - j < d)) then
		npPosX := d + j;

	{ update pos }
	pPosX := npPosX;
	pPosZ := npPosZ;
end;

procedure drawPlayers;
begin
	glPushMatrix;
		glTranslatef(-mazeW / 2, 0, -mazeH / 2);
		glPushMatrix;
			glColor4f(0, 0.75, 0, 1);
			glTranslatef(pPosX, MAZE_BALL / 2, pPosZ);
			glutWireSphere(MAZE_BALL / 2, 10, 10);
		glPopMatrix;
		glPushMatrix;
			glColor4f(0.75, 0, 0, 1);
			glTranslatef(cPosX, MAZE_BALL / 2, cPosZ);
			glutWireSphere(MAZE_BALL / 2, 10, 10);
		glPopMatrix;
	glPopMatrix;
end;

procedure setCam;
const
	lambient:  array[0..3] of GLfloat = ( 0.2, 0.2,  0.2, 1.0);
	ldiffuse:  array[0..3] of GLfloat = ( 0.8, 0.8,  0.8, 1.0);
	lspecular: array[0..3] of GLfloat = ( 0.5, 0.5,  0.5, 1.0);
begin
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity;

	{
	gluLookAt(camX + (pPosX - mazeW/2), camY, camZ + (pPosZ - mazeH/2),
				(pPosX - mazeW/2), 0.0, (pPosZ - mazeH/2),
				0, 1.0, 0);
	}
	gluLookAt(camX, camY, camZ,
				0.0, 0.0, 0.0,
				0.0, 1.0, 0.0);

	glLightfv(GL_LIGHT0, GL_AMBIENT, lambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, ldiffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, lspecular);
	glLightfv(GL_LIGHT0, GL_POSITION, liXYZ);
end;

procedure drawMenu;
begin
	t2 := t2 + dt;

	if (menu = 6) then begin
		drawText(-2, 1, format('maze height: %d', [menuH]));
		drawText(-2, 0, format('maze width:  %d', [menuW]));
		drawText(-2, -1, '(use arrows to change)');

		if (kUp) and (t2 > 0.1) and (menuH < 200) then begin
			menuH := menuH + 1;
			t2 := 0;
		end;
		if (kDn) and (t2 > 0.1) and (menuH > 1) then begin
			menuH := menuH - 1;
			t2 := 0;
		end;
		if (kRg) and (t2 > 0.1) and (menuW < 200) then begin
			menuW := menuW + 1;
			t2 := 0;
		end;
		if (kLf) and (t2 > 0.1) and (menuW > 1) then begin
			menuW := menuW - 1;
			t2 := 0;
		end;
		if (kSh) and (t2 > 0.3) then begin
			dfsMaze(menuH, menuW);
			solveMaze;
			t1 := 0;
			menu := 0;
			t2 := 0;
			allBlocked := false;
			glEnable(GL_LIGHTING);
			glEnable(GL_LIGHT0);
		end;
		exit;
	end;

	if (menu = 7) then begin
		drawText(-2, 0.5, format('enemy speed: %.3f [cells/s]', [cSpeed]));
		drawText(-2, -0.5, '(use arrows to change)');

		if (kUp) and (t2 > 0.1) and (cSpeed < 15) then begin
			cSpeed := cSpeed + 0.05;
			t2 := 0;
		end;
		if (kDn) and (t2 > 0.1) and (cSpeed > 0.05) then begin
			cSpeed := cSpeed - 0.05;
			t2 := 0;
		end;
		if (kSh) and (t2 > 0.3) then begin
			t2 := 0;
			menu := 1;
		end;
		exit;
	end;

	if (menu = 8) then begin
		drawText(-2, 0, 'saved to $(PWD)/lab.txt');
		if (kSh) and (t2 > 0.3) then begin
			t2 := 0;
			menu := 1;
		end;
		exit;
	end;

	if (menu = 9) then begin
		drawText(-2, 0, 'loaded from $(PWD)/lab.txt');
		if (kSh) and (t2 > 0.3) then begin
			t2 := 0;
			menu := 1;
		end;
		exit;
	end;

	if (kDn) and (t2 > 0.1) then begin
		menu := 1 + (5 + (menu - 1 + 1) mod 5) mod 5;
		t2 := 0;
	end;
	if (kUp) and (t2 > 0.1) then begin
		menu := 1 + (5 + (menu - 1 - 1) mod 5) mod 5;
		t2 := 0;
	end;

	if (kSh) and (t2 > 0.3) then begin
		if (menu = 1) then begin
			menu := 6;
			t2 := 0;
			exit;
		end else if (menu = 2) then begin
			menuFile := '';
			menu := 8;
			t2 := 0;
			saveMaze('lab.txt');
			exit;
		end else if (menu = 3) then begin
			menuFile := '';
			menu := 9;
			t2 := 0;
			readMaze('lab.txt');
			solveMaze;
			t1 := 0;
			exit;
		end else if (menu = 4) then begin
			menu := 7;
			t2 := 0;
			exit;
		end else if (menu = 5) then begin
			glutLeaveGameMode;
			halt(0);
		end;

		menu := 0;
		t2 := 0;
		allBlocked := false;
		glEnable(GL_LIGHTING);
		glEnable(GL_LIGHT0);
		exit;
	end;

	if (menu = 1) then begin glColor4f(1, 0, 0, 1); end else begin glColor4f(1, 1, 1, 1); end;
	drawText(-2, 2, 'generate random DFS maze');

	if (menu = 2) then begin glColor4f(1, 0, 0, 1); end else begin glColor4f(1, 1, 1, 1); end;
	drawText(-2, 1, 'save current maze to file');

	if (menu = 3) then begin glColor4f(1, 0, 0, 1); end else begin glColor4f(1, 1, 1, 1); end;
	drawText(-2, 0, 'load maze from file');

	if (menu = 4) then begin glColor4f(1, 0, 0, 1); end else begin glColor4f(1, 1, 1, 1); end;
	drawText(-2, -1, 'set enemy speed [cells/s]');

	if (menu = 5) then begin glColor4f(1, 0, 0, 1); end else begin glColor4f(1, 1, 1, 1); end;
	drawText(-2, -2, 'exit');
end;

procedure drawStats;
begin
	glColor4f(1, 1, 1, 1);
	drawText(-10,  -6.0, format('Controls:     Up/Dn/Lf/Rg, Space', []));
	drawText(-10,  -6.5, format('Camera:       E/D/S/F, A/Z', []));
	drawText(-10,  -7.0, format('FPS:          %.3f [Hz]', [1 / dt]));
	drawText(-10,  -7.5, format('Height/width: %d x %d [cells^2]', [mazeH, mazeW]));
	drawText(-10,  -8.0, format('Enemy speed:  %.3f [cells/s]', [cSpeed]));
end;

procedure drawScene;
begin
	glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

	if (menu > 0) then begin
		drawMenu;
	end else begin
		drawStats;
		setCam;
		drawMaze;
		drawPlayers;
	end;

	glutSwapBuffers;
end;

procedure loop; cdecl;
begin
	dt := t0;
	t0 := glutGet(GLUT_ELAPSED_TIME) / 1000;
	dt := t0 - dt;

	userInput;
	moveEnemy;
	resolveCollisions;
	drawScene;
end;

procedure resize (w, h: longint); cdecl;
begin
	if (h = 0) then
		h := 1;

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glViewport(0, 0, w, h);

	gluPerspective(45, w / h, 1, 1000);
	setCam;
end;

procedure keyNormDn (key: byte; x, y: longint); cdecl;
begin
	if (key = LongWord('e')) then begin
		kE := true;
	end else if (key = LongWord('d')) then begin
		kD := true;
	end else if (key = LongWord('f')) then begin
		kF := true;
	end else if (key = LongWord('s')) then begin
		kS := true;
	end else if (key = LongWord('a')) then begin
		kA := true;
	end else if (key = LongWord('z')) then begin
		kZ := true;
	end else if (key = LongWord(' ')) then begin
		kSh := true;
	end else if (key = LongWord(13) { enter }) then begin
		kSh := true;
	end else if (key = 27 {esc}) then begin
		if (menu > 0) then begin menu := 0; end else begin menu := 1; end;
		allBlocked := (menu > 0);
		if (menu > 0) then begin
			glDisable(GL_LIGHTING);
			glDisable(GL_LIGHT0);
		end else begin
			glEnable(GL_LIGHTING);
			glEnable(GL_LIGHT0);
		end;
	end;
end;

procedure keyNormUp (key: byte; x, y: longint); cdecl;
begin
	if (key = LongWord('e')) then begin
		kE := false;
	end else if (key = LongWord('d')) then begin
		kD := false;
	end else if (key = LongWord('f')) then begin
		kF := false;
	end else if (key = LongWord('s')) then begin
		kS := false;
	end else if (key = LongWord('a')) then begin
		kA := false;
	end else if (key = LongWord('z')) then begin
		kZ := false;
	end else if (key = LongWord(' ')) then begin
		kSh := false;
	end else if (key = LongWord(13) { enter }) then begin
		kSh := false;
	end;
end;

procedure keySpecDn (key, x, y: GLint); cdecl;
begin
	if (key = GLUT_KEY_UP) then begin
		kUp := true;
	end else if (key = GLUT_KEY_RIGHT) then begin
		kRg := true;
	end else if (key = GLUT_KEY_DOWN) then begin
		kDn := true;
	end else if (key = GLUT_KEY_LEFT) then begin
		kLf := true;
	end;
end;

procedure keySpecUp (key, x, y: longint); cdecl;
begin
	if (key = GLUT_KEY_UP) then begin
		kUp := false;
	end else if (key = GLUT_KEY_RIGHT) then begin
		kRg := false;
	end else if (key = GLUT_KEY_DOWN) then begin
		kDn := false;
	end else if (key = GLUT_KEY_LEFT) then begin
		kLf := false;
	end;
end;

procedure initGL;
begin
	glutSetCursor(GLUT_CURSOR_NONE);

	glutIgnoreKeyRepeat(1);
	glutKeyboardFunc(@keyNormDn);
	glutKeyboardUpFunc(@keyNormUp);
	glutSpecialFunc(@keySpecDn);
	glutSpecialUpFunc(@keySpecUp);

	glutDisplayFunc(@loop);
	glutIdleFunc(@loop);
	glutReshapeFunc(@resize);

	glEnable(GL_DEPTH_TEST);
	glShadeModel(GL_SMOOTH);
	glClearColor(0.0, 0.0, 0.0, 0.5);
	glClearDepth(1.0);
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);

	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
end;

procedure init;
begin
	randomize;

	allBlocked := false;

	cSpeed := 3.0;
	menuW := 7; menuH := 7;

	kSh := false;
	kUp := false; kDn := false; kRg := false; kLf := false;
	kE := false; kD := false; kF := false; kS := false;
	kA := false; kZ := false;

	camR := 17.5; camPhi := 60; camTheta := 37.5;

	dfsMaze(menuH, menuW);
	solveMaze;
	t1 := 0;

	t0 := glutGet(GLUT_ELAPSED_TIME) / 1000;
	dt := 0;
end;

{
	1/ wczytywanie z pliku: lab.txt
	2/ zapis do pliku: lab.txt
	3/ wysw. ze nie da sie przejsc
	4/ wysw. kto wygral

	c++	
		fps usredniane np. z 0.2 [s]
		FPP [tab]? =) + kompas
		collisions (hash map? N-tutorial)
		wyjscie i wejscie na scianach zewn.
			wtedy oznaczac przez dziure w scianie
		lepszy algorytm gen.
			http://www.astrolog.org/labyrnth/algrithm.htm

}

begin
	glutInit(@argc, @argv);
	glutInitDisplayMode(GLUT_DEPTH or GLUT_DOUBLE or GLUT_RGBA);

	{ glutInitWindowSize(800, 600);
	glutCreateWindow('project'); }
	glutEnterGameMode;

	init;
	initGL;

	glutMainLoop;
end.