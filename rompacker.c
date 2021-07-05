
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


static unsigned char memory[65536];
static char *program_name;

static void insert_binary(char *filename, int address);

static void exit_log(int code, char *fmt, ...)
{
    va_list  ap;

    va_start(ap, fmt);
    if ( fmt != NULL ) {
        if ( program_name ) {
            fprintf(stderr, "%s: ", program_name);
        }

        vfprintf(stderr, fmt, ap);
    }

    va_end(ap);
    exit(code);
}

int main(int argc, char **argv)
{
    int romsize,i;
    FILE *fp;

    program_name = argv[0];

    if ( argc < 3 ) {
        exit_log(1,"Usage [outfile] [romsize] {[binary]:[address]}\n");
    }

    romsize = strtol(argv[2],NULL, 0);

    if ( romsize == 0 ) {
        exit_log(1,"Cannot parse rom size %s\n",argv[2]);
    }
   

    for ( i = 3; i < argc; i++ ) {
         char *ptr = strchr(argv[i], ':');
         long  addr;

         if ( ptr == NULL ) {
             exit_log(1,"Cannot parse rom size %s\n",argv[1]);
         }
         if ( (addr = strtol(ptr+1, NULL, 0)) == 0 ) {
             exit_log(1,"Cannot parse argument %s\n",argv[i]);
         }
         *ptr++ = 0;

         insert_binary(argv[i], addr);
    }

    if ( (fp = fopen(argv[1],"wb")) != NULL ) {
        if (fwrite(memory + 65536 - romsize, 1, romsize, fp) != romsize ) {
            exit_log(1,"Could not write assembled ROM\n");
        }
        fclose(fp);
    }
    exit(0);
}

static void insert_binary(char *filename, int address)
{
     FILE *fp;
     long  filesize;

     if ( (fp = fopen(filename, "rb") ) != NULL ) {
         if (fseek(fp, 0, SEEK_END)) {
             fclose(fp);
             exit_log(1,"Couldn't determine the size of the file %s\n",filename);
         }

         filesize = ftell(fp);
         if (filesize+address > 65536L) {
             fclose(fp);
             exit_log(1,"The file %s would overflow the rom\n",filename);
         }

         fseek(fp, 0, SEEK_SET);
         if (fread(memory+address, 1, filesize, fp) != filesize ) {
             exit_log(1,"Didn't read enough data from file %s\n",filename);
         }
         fclose(fp);
     } else {
         exit_log(1,"Couldn't open file %s\n",filename);
     }

}
