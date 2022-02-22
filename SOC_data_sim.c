
// This program generates a csv file with data on a simulated state of charge (SOC)
// estimate for a vehicle. It also prints the data in the console (output).
// Time duration of data: 9000s
// Time interval of data: every 10s (this can be modified)
// Created by Ayush Saha, 2/14/2022


#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
#include <math.h>


// circuit model parameters
double Cc = 0.15;
double Rc = 150;
double Cbat = 1; // units in Amp * s

// State variables
long double SOCk = 1.0;
long double vk = 0.0;
// next values of state variables
long double SOCkp1;
long double vkp1;

// current load functions
double get_It_constant(int t);
double get_It_toggle(int t);
double get_It_piecewise(int t);
// current load function and value
double (*func_It)(int) = &get_It_toggle; // choose current function here
double It;

// Linked list struct
struct node {
	int t;
	long double soc;
	long double v;
	double i;
	struct node* next;
};

// WE MUST HAVE A POINTER TO HEAD OF LIST AND POINTER TO CURRENT ELEM
struct node* head = NULL;
struct node* current = NULL;


// INSERT LINK AT THE FIRST LOCATION
void insertFirst(int t_val, long double soc_val, long double v_val, double i_val) {
	//create a link
	struct node* link = (struct node*)malloc(sizeof(struct node));

	link->t = t_val;
	link->soc = soc_val;
	link->v = v_val;
	link->i = i_val;

	current = head = link;
	link->next = NULL;
}

// Insert link at end
struct node* insertAtEnd(int t_val, long double soc_val, long double v_val, double i_val) {
	//create a link
	struct node* link = (struct node*)malloc(sizeof(struct node));
	link->t = t_val;
	link->soc = soc_val;
	link->v = v_val;
	link->i = i_val;
	link->next = NULL;

	current->next = link;
	current = link;
	return link;
}

// PRINTING THE LIST
void printList() {
	struct node* ptr = head;

	while (ptr != NULL) {
		printf("%d\t%.9Lf\t%.9Lf\t%.9f\n", ptr->t, ptr->soc, ptr->v, ptr->i);
		ptr = ptr->next;
	}
}

// FINDING LENGTH OF LINKED LIST
int length() {
	int length = 0;
	struct node* current;

	for (current = head; current != NULL; current = current->next) {
		length++;
	}
	return length;
}


// Print the linked list into csv file
int print_list_into_csv(FILE** fp) {
	struct node* ptr = head;
	while (ptr != NULL) {
		fprintf(*fp, "%d,%.9Lf,%.9Lf,%.9f\n", ptr->t, ptr->soc, ptr->v, ptr->i);
		ptr = ptr->next;
	}
	return 0;
}

// Discrete solution to
//
//     d/dt(soc) = - It / Cbat
//     d/dt(v) = (It / Cc) - v / (Cc * Rc)
//
// Using finite difference (x_{k+1} - x_{k})/dt approx d/dt(x)
long double func_SOCkp1(long double SOCk, int dt, double It, double Cbat) {
	long double SOCkp1 = SOCk - dt * (It / Cbat);
	return SOCkp1;
}

long double func_vkp1(long double vk, int dt, double It, double Cc, double Rc) {
	long double vkp1 = vk + dt * ((It / Cc) - (vk / (Cc * Rc)));
	return vkp1;
}

// SECTION: options for getting current load: It
// all should have int t as an argument

// Constant
double get_It_constant(int t) {
	return 0.01;
}

// Toggle on/off
double get_It_toggle(int t) {
	t = t % 1000;
	if (t < 500) {
		return 0.01;
	} else {
		return 0;
	}
}

// Piecewise function
double get_It_piecewise(int t) {
	// First interval
	if ((0 <= t && t < 1000) || (3000 <= t && t < 4000) || (6000 <= t && t < 7000)) {
		return 0.0003;
		//supposed_slope = -0.0003;
		//random_slope = supposed_slope * ((double)(random_direction + random_slope_magnification));
		//random_slope -= 0.0001;
		//if (rand() % 11 == 3 && random_slope > 0.000)
		//	random_slope *= 1.7;
		// y = (double)y_prev + (random_slope * t_interval);
	}
	// Second interval
	else if ((1000 <= t && t < 2000) || (4000 <= t && t < 5000) || (7000 <= t && t < 8000)) {
		return 0;
		// supposed_slope = 0;
		//	random_slope = ((double)(random_direction * random_slope_magnification * 0.00015));
		//	if (rand() % 11 == 3 && random_slope >= -0.0003)
		//		random_slope *= 1.7;
		//	y = (double)y_prev + (random_slope * t_interval);
	}
	// Third interval
	else if ((2000 <= t && t < 2500) || (5000 <= t && t < 5500) || (8000 <= t && t < 8500)) {
		return -0.00041;
		//supposed_slope = 0.00041;
		//random_slope = supposed_slope * ((double)(random_direction + random_slope_magnification));
		////random_slope -= 0.0001;
		//if (rand() % 11 == 3 && random_slope <= 0.0003)
		//	random_slope *= 1.7;
		//y = (double)y_prev + (random_slope * t_interval);
	}
	// Fourth interval
	else if ((2500 <= t && t < 3000) || (5500 <= t && t < 6000) || (8500 <= t && t < 9000)) {
		return 0;
		//supposed_slope = 0;
		//random_slope = ((double)(random_direction * random_slope_magnification * 0.00015));
		//if (rand() % 11 == 3 && random_slope >= -0.0003)
		//	random_slope *= 1.7;
		//y = (double)y_prev + (random_slope * t_interval);
	}
	return 0;
}

// END SECTION: options for getting current load: It


// DRIVER CODE
int main() {
	// time variable declarations
	int dt = 10;
	int num_seconds = 9000; // max duration of sim data
	int t = 0;
	
	bool start_new_list = false;
	bool done_csv_printing = false;

	// Very first value
	It = (*func_It)(0);
	insertFirst(t, SOCk, vk, It);
	t += dt;

	// Opening the csv file
	FILE* fp;
	fp = fopen("data_sim.csv", "w");
	if (fp == NULL) {
		printf("Can't be opened");
		return 1;
	}
	
	// Variables used for random scatter generation algorithm
	srand(time(NULL));		// This and few lines below are for random data generator algorithm
	int random_direction;
	//double random_slope, random_slope_magnification, supposed_slope;
	double random_slope_magnification;

	bool one_direction = false;		// This and few lines below are for random direction chooser algorithm
	int memorized_direction;
	int stored_t_val = t;
	int tot_num_times_one_direc_deployed = 25;
	int one_direc_rand_chooser_lim = (num_seconds / dt) / tot_num_times_one_direc_deployed;
	int one_direc_rand_chosen = one_direc_rand_chooser_lim / 2;


	// THE BIG WHILE LOOP
	while (t <= num_seconds) {

		// sometimes we send the data all positive for some time. This is the algorithm for that
		// randomly chose a set direction to follow
		if (rand() % (one_direc_rand_chooser_lim + 1) == one_direc_rand_chosen) {
			one_direction = true;
			stored_t_val = t;
			memorized_direction = rand() % 2;
			if (memorized_direction == 0)
				memorized_direction = -1;
		}
		// stick with that set value
		if (one_direction == true) {
			random_direction = memorized_direction;
			//printf("start");
			if (t - stored_t_val > 120) {
				one_direction = false;
				//printf("end\n");
			}
		}
		// or if not, just choose a new random direction
		else {
			random_direction = rand() % 2;
			if (random_direction == 0)
				random_direction = -1;
		}

		//----------------GENERATING Y-COOR.----------------

		random_slope_magnification = ((double)rand() / RAND_MAX * 1.0 - 1.0) * (-1);//float in range 0 to 1
		//printf("%.2lf\t", random_slope_magnification);
		//printf("%d\n", random_direction);

		// get current value at time t
		It = (*func_It)(t);

		// Calculate next SOC and Vc using discrete solution
		SOCkp1 = func_SOCkp1(SOCk, dt, It, Cbat);		
		vkp1 = func_vkp1(vk, dt, It, Cc, Rc);

		// Inserting the (t,soc,v) coordinate into linked list
		if (start_new_list == true) {
			insertFirst(t, SOCkp1, vkp1, It);
			start_new_list = false;
		}
		else {
			insertAtEnd(t, SOCkp1, vkp1, It);
		}
		// Inserting the linked list into the csv
		// only take every 50th value to reduce file size
		if (t % (dt * 50) == 0) {
			print_list_into_csv(&fp);
			printList();
			if (t == num_seconds) {
				done_csv_printing = true;
			}
			start_new_list = true;
			current = head;
		}
		// Important variable changes for each run of loop
		vk = vkp1;
		SOCk = SOCkp1;
		t += dt;
	}
	// print last few elements into csv after while loop is over
	if (done_csv_printing == false) {
		print_list_into_csv(&fp);
		printList();
	}

	// Close csv
	fclose(fp);
	fp = NULL;
	return 0;
}
