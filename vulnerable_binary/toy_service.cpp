#include <iostream>
#include <typeinfo>
#include <memory>
#include <cstring>

using namespace std;
// Base class with virtual functions
class Base
{
public:
    virtual ~Base() = default;
    virtual void foo()
    {
        std::cout << "Base::foo()" << std::endl;
    }
    virtual int getValue()
    {
        return 42;
    }
};

// Derived class
class Derived : public Base
{
public:
    void foo() override
    {
        std::cout << "Derived::foo()" << std::endl;
    }
    int getValue() override
    {
        return 100;
    }
    virtual void derivedOnly()
    {
        std::cout << "Derived::derivedOnly()" << std::endl;
    }
};

// Unrelated class with different vtable layout
class Unrelated
{
public:
    virtual ~Unrelated() = default;
    virtual void bar()
    {
        std::cout << "Unrelated::bar()" << std::endl;
    }
    virtual void baz()
    {
        std::cout << "Unrelated::baz()" << std::endl;
    }
};

void integerOverflow(const int b)
{
    int a = 2147483647; // Maximum value for a 32-bit signed integer
    int c = a + b;                                              // This will overflow
    std::cout << "Integer overflow result: " << c << std::endl; // Undefined behavior
    return;
}
void strcpyOutOfBounds(const char str[])
{
    char buffer[2];
    // Use strcpy directly - _FORTIFY_SOURCE will catch this
    strcpy(buffer, str);
    std::cout << "Copied string: " << buffer << std::endl;
}

int8_t useAfterFree()
{
    int *array = new int[100];
    delete[] array;
    int index = 96;
    cout << "Accessing array after free: " << array[index] << std::endl;
    return array[index]; // BOOM
}

// Another vulnerable function using references
void badCast()
{
    // Create an Unrelated object
    Unrelated *unrelated = new Unrelated();

    // This is a bad cast - casting an Unrelated* to Base*
    // This violates type safety and will trigger CFI
    std::cout << "\nAttempting bad cast from Unrelated* to Base*..." << std::endl;
    Base *bad_ptr = reinterpret_cast<Base *>(unrelated);

    // This virtual function call through the bad pointer will trigger CFI
    std::cout << "Calling virtual function through bad pointer..." << std::endl;
    bad_ptr->foo(); // CFI violation - will abort here

    // This line won't be reached when CFI is enabled
    std::cout << "If you see this, CFI recovered or didn't catch the violation!" << std::endl;

    delete unrelated;
    return;
}

int main(int argc, char *argv[])
{
    std::cout << "=== Starting toy_service ===" << std::endl;
    if (argc == 2)
    {
        const char *argument = argv[1];
        std::cout << "Command line arguments provided: " << std::endl;
        //
        // use_after_free AddressSanitizer will catch this
        //
        if (argument == "use_after_free"s)
        {
            std::cout << "Calling useAfterFree." << std::endl;
            useAfterFree();
        }
        else if (argument == "bad_cast"s)
        {
            std::cout << "Calling badCast." << std::endl;
            badCast();
        }
        else if (argument == "integer_overflow"s)
        {
            std::cout << "Calling integerOverflow." << std::endl;
            integerOverflow(2);
        }
        else if (argument == "strcpy_out_of_bounds"s)
        {
            std::cout << "Calling strcpyOutOfBounds." << std::endl;
            strcpyOutOfBounds("Overflow!");
        }
        else
        {
            std::cout << "Unknown command line argument: " << argument << std::endl;
        }
    }
    else
    {
        std::cout << "No command line arguments provided." << std::endl;
    }
    std::cout << "Toy Service run complete." << std::endl;
    return 0;
}