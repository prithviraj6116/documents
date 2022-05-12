#include <iostream>
#include <iomanip>
#include "elf++.hh"
#include "dwarf++.hh"
#include <inttypes.h>
#include <fcntl.h>
//backup at //mathworks/devel/sandbox/ppatil/_sbbackup/local_ppatil_local-ssd_ppatil_esc2_backup/stackviewer_1
//#define BOOST_STACKTRACE_USE_ADDR2LINE
//#include <boost/stacktrace.hpp>
__attribute__ ((__noinline__))
void * get_pc0 () { return __builtin_return_address(0); }
__attribute__ ((__noinline__))
void * get_pc1 () { return __builtin_return_address(1); }
__attribute__ ((__noinline__))
void * get_pc2 () { return __builtin_return_address(2); }

           //for (auto &attr : die.attributes()) {
           //    printf("%s %s\n", to_string(attr.first).c_str(), to_string(attr.second).c_str());
void
dump_tree(const dwarf::die &node, int depth, uint64_t pc)
{

    if (node.tag == dwarf::DW_TAG::subprogram) {
        if (die_pc_range(node).contains(pc)) {
            printf("found function.\n%*.s<%" PRIx64 "> %s\n", depth, "", node.get_section_offset(), to_string(node.tag).c_str());
            for (auto &attr : node.attributes()) {
                printf("%*.s      %s %s\n", depth, "", to_string(attr.first).c_str(), to_string(attr.second).c_str());
            }
        }
    }
    for (auto &child : node)
        dump_tree(child, depth + 3, pc);
}

dwarf::die get_function_from_pc(uint64_t pc, elf::elf & ef, dwarf::dwarf&dw) {
    for (auto cu : dw.compilation_units()) {
        printf("--- <%" PRIx64 ">\n", cu.get_section_offset());
        if (die_pc_range(cu.root()).contains(pc)) {
            printf("---found cu-------\n");
            for (auto &attr : cu.root().attributes()) {
                printf("%*.s      %s %s\n", 0, "", to_string(attr.first).c_str(), to_string(attr.second).c_str());
            }
            for (auto& node : cu.root()) {
                if (node.tag == dwarf::DW_TAG::subprogram) {
                    if (die_pc_range(node).contains(pc)) {
                        printf("found function.\n%*.s<%" PRIx64 "> %s\n", 0, "", node.get_section_offset(), to_string(node.tag).c_str());
                        for (auto &attr : node.attributes()) {
                            printf("%*.s      %s %s\n", 0, "", to_string(attr.first).c_str(), to_string(attr.second).c_str());
                        }
                        return node;
                    }
                }
            }
        }
    }
    throw std::out_of_range{"Cannot find function"};
}

#include <sys/ptrace.h>
#include "registers.hpp"
#include <unistd.h>
class ptrace_expr_context : public dwarf::expr_context {
public:
    ptrace_expr_context (pid_t pid, uint64_t load_address) : 
       m_pid{pid}, m_load_address(load_address) {}

    dwarf::taddr reg (unsigned regnum) override {
        return get_register_value_from_dwarf_register(m_pid, regnum);
    }

    dwarf::taddr pc()  {
        struct user_regs_struct regs;
        ptrace(PTRACE_GETREGS, m_pid, nullptr, &regs);
        return regs.rip - m_load_address;
    }

    dwarf::taddr deref_size (dwarf::taddr address, unsigned size) override {
        //TODO take into account size
        return ptrace(PTRACE_PEEKDATA, m_pid, address + m_load_address, nullptr);
    }

private:
    pid_t m_pid;
    uint64_t m_load_address;
};
uint64_t read_memory(uint64_t address, pid_t m_pid) {
    return ptrace(PTRACE_PEEKDATA, m_pid, address, nullptr);
}

void read_variables(dwarf::die& func, uint64_t m_load_address) {
    using namespace dwarf;

    for (const auto& die : func) {
        if (die.tag == DW_TAG::variable) {
            auto loc_val = die[DW_AT::location];

            //only supports exprlocs for now
            if (loc_val.get_type() == value::type::exprloc) {
                ptrace_expr_context context {getpid(), m_load_address};
                auto result = loc_val.as_exprloc().evaluate(&context);

                switch (result.location_type) {
                case expr_result::type::address:
                {
                    auto offset_addr = result.value;
                    auto value = read_memory(offset_addr, getpid());
                    std::cout << at_name(die) << " (0x" << std::hex << offset_addr << ") = " << value << std::endl;
                    break;
                }

                case expr_result::type::reg:
                {
                    auto value = get_register_value_from_dwarf_register(getpid(), result.value);
                    std::cout << at_name(die) << " (reg " << result.value << ") = " << value << std::endl;
                    break;
                }

                default:
                    throw std::runtime_error{"Unhandled variable location"};
                }
            }
            else {
                throw std::runtime_error{"Unhandled variable location"};
            }
        }
    }
}

void my_func_3(void) {
    unsigned long int loadAddress = 0x4000;
    unsigned long int lowerBytePC = reinterpret_cast<unsigned long int>(get_pc0()) & 0xffff - loadAddress;
    std::cout << std::hex << "lowerBytePC:" << lowerBytePC << std::endl;
    int fd = open("/local-ssd/ppatil/gitRepo1/libelfin/examples/cpp1", O_RDONLY);
    if (fd < 0) {
        throw std::out_of_range{"Cannot find function"};
    }
    elf::elf ef(elf::create_mmap_loader(fd));
    dwarf::dwarf dw(dwarf::elf::create_loader(ef));
    auto fcn = get_function_from_pc(lowerBytePC, ef, dw);
    read_variables(fcn, loadAddress);
}
void my_func_2(void) {
    my_func_3();
}


void my_func_1() {
    my_func_2();
}

void* get_register_values(unsigned int reg) {
    int j = 1;
    switch(reg) {
    case 1:
        register void* eax asm("eax");
        return eax;
    default:
        register void* r11 asm("r11");
        return r11;
    }
}
int main() {
    void *k1 = get_register_values(1);
    void *k2 = get_register_values(2);
    my_func_1();
    std::cout << std::hex << "eax:" << k1 << std::endl;
    std::cout << std::hex << "r11:" << k2 << std::endl;
}
