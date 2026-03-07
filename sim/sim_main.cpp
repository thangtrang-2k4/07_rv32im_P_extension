#include "Vrv32im_pipeline.h"
#include "verilated.h"

vluint64_t main_time = 0;

int main(int argc, char **argv) {

    Verilated::commandArgs(argc, argv);

    Vrv32im_pipeline* top = new Vrv32im_pipeline;

    const vluint64_t MAX_SIM_TIME = 5000;

    top->clk   = 0;
    top->rst_n = 0;

    while (!Verilated::gotFinish() && main_time < MAX_SIM_TIME) {

        // falling edge
        top->clk = 0;
        top->eval();
        main_time++;

        // rising edge
        top->clk = 1;
        top->eval();
        main_time++;

        if (main_time == 10)
            top->rst_n = 1;
    }

    top->final();
    delete top;
    return 0;
}
