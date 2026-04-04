# CLAUDE.md — Guia NestJS

## Papel e Responsabilidades

Você é o desenvolvedor sênior TypeScript/NestJS deste projeto. Ao receber uma solicitação:

- Crie todos os arquivos necessários (módulos, controllers, services, DTOs, entities, testes)
- Edite arquivos existentes sem pedir permissão
- Corrija bugs encontrados durante a implementação
- Siga rigorosamente os padrões descritos neste guia

---

## Stack e Versões

| Tecnologia | Versão |
|-----------|--------|
| Node.js | 22 |
| NestJS | 11 |
| TypeScript | 5.7 |
| Jest | 30 |
| ESLint | 9 |
| Prettier | 3 |

---

## Arquitetura de Módulos

Cada domínio/recurso principal é encapsulado em um módulo com a seguinte estrutura:

```
src/
├── core/                          # Módulo global (infraestrutura NestJS)
│   ├── filters/                   # Filtros globais de exceção
│   ├── guards/                    # Guards de autenticação/autorização
│   ├── interceptors/              # Interceptors globais
│   ├── middlewares/               # Middlewares globais
│   └── core.module.ts
├── shared/                        # Módulo compartilhado entre domínios
│   ├── utils/                     # Utilitários reutilizáveis
│   └── shared.module.ts
└── <domain>/                      # Módulo de domínio (ex: users, products)
    ├── models/                    # Tipos e interfaces do domínio
    ├── dto/                       # Data Transfer Objects (entrada validada)
    ├── entities/                  # Entidades de persistência (MikroORM)
    ├── <domain>.controller.ts     # Controller principal
    ├── <domain>.service.ts        # Serviço principal
    └── <domain>.module.ts         # Módulo do domínio
```

---

## Convenções TypeScript

### Nomenclatura

| Elemento | Padrão | Exemplo |
|----------|--------|---------|
| Classes | PascalCase | `UserService`, `CreateUserDto` |
| Funções/Métodos | camelCase + verbo | `findUserById`, `createUser` |
| Variáveis | camelCase | `userName`, `isActive` |
| Booleanos | verbo prefixado | `isLoading`, `hasError`, `canDelete` |
| Arquivos | kebab-case | `user.service.ts`, `create-user.dto.ts` |
| Env vars | UPPER_SNAKE_CASE | `DATABASE_URL`, `JWT_SECRET` |
| Constantes | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS` |

### Funções

```typescript
// CORRETO: função curta com único propósito, RO-RO pattern
async function findUserById({ id }: FindUserByIdInput): Promise<UserOutput> {
  const user = await this.userRepository.findOne({ id });
  if (!user) throw new NotFoundException(`User ${id} not found`);
  return mapToUserOutput(user);
}

// ERRADO: parâmetros primitivos soltos, sem tipos explícitos
async function getUser(id, includeDeleted) { ... }
```

### Tipos

```typescript
// Declarar tipos de entrada e saída
type FindUserByIdInput = { readonly id: string };
type UserOutput = { readonly id: string; readonly email: string; readonly name: string };

// Evitar any — usar unknown ou generics quando necessário
function parseResponse<T>(data: unknown): T { ... }
```

---

## DTOs com class-validator

```typescript
import { IsEmail, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsString()
  readonly name: string;

  @IsEmail()
  readonly email: string;

  @IsString()
  @MinLength(8)
  readonly password: string;
}
```

---

## Controllers

```typescript
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  /** Smoke test — verifica se o módulo está operacional */
  @Get('test')
  test(): { status: string } {
    return { status: 'ok' };
  }

  @Post()
  async createUser(@Body() dto: CreateUserDto): Promise<UserOutput> {
    return this.userService.createUser(dto);
  }

  @Get(':id')
  async findUser(@Param('id') id: string): Promise<UserOutput> {
    return this.userService.findUserById({ id });
  }
}
```

**Regras:**
- Sempre incluir rota `GET /test` como smoke test
- Usar DTOs tipados para `@Body()`
- Retornar tipos simples (não entidades diretas)
- Um controller por rota principal

---

## Services

```typescript
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: EntityRepository<User>,
  ) {}

  async createUser(dto: CreateUserDto): Promise<UserOutput> {
    const user = this.userRepository.create(dto);
    await this.userRepository.persistAndFlush(user);
    return mapToUserOutput(user);
  }

  async findUserById({ id }: FindUserByIdInput): Promise<UserOutput> {
    const user = await this.userRepository.findOne({ id });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return mapToUserOutput(user);
  }
}
```

**Regras:**
- Um service por entidade
- Nunca retornar entidades diretamente — mapear para output types
- Lançar exceções NestJS (`NotFoundException`, `BadRequestException`, etc.)

---

## Testes

### Unitários (`.spec.ts`) — Padrão Arrange-Act-Assert

```typescript
describe('UserService', () => {
  let service: UserService;
  let mockUserRepository: jest.Mocked<EntityRepository<User>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: getRepositoryToken(User),
          useValue: { findOne: jest.fn(), create: jest.fn(), persistAndFlush: jest.fn() },
        },
      ],
    }).compile();

    service = module.get(UserService);
    mockUserRepository = module.get(getRepositoryToken(User));
  });

  describe('findUserById', () => {
    it('should return user when found', async () => {
      // Arrange
      const inputId = 'user-123';
      const mockUser = { id: inputId, name: 'John', email: 'john@example.com' };
      mockUserRepository.findOne.mockResolvedValue(mockUser as User);

      // Act
      const actualUser = await service.findUserById({ id: inputId });

      // Assert
      expect(actualUser).toEqual({ id: inputId, name: 'John', email: 'john@example.com' });
    });

    it('should throw NotFoundException when user not found', async () => {
      // Arrange
      mockUserRepository.findOne.mockResolvedValue(null);

      // Act & Assert
      await expect(service.findUserById({ id: 'nonexistent' })).rejects.toThrow(NotFoundException);
    });
  });
});
```

### E2E (`test/*.e2e-spec.ts`) — Padrão Given-When-Then

```typescript
describe('UserController (e2e)', () => {
  it('GET /users/test — should return status ok', async () => {
    // Given: a running application

    // When
    const response = await request(app.getHttpServer()).get('/users/test');

    // Then
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });
});
```

**Regras:**
- Testes unitários para cada método público de service e controller
- Testes e2e para cada módulo/rota
- Nomear variáveis: `inputX`, `mockX`, `actualX`, `expectedX`

---

## Módulo Core

Registrado globalmente no `AppModule`. Contém filtros, guards e interceptors:

```typescript
// core/filters/http-exception.filter.ts
@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const status = exception.getStatus();
    res.status(status).json({ statusCode: status, message: exception.message });
  }
}
```

---

## Comandos no Container

```bash
# Dentro de /workspace/nest-app

npm run start:dev         # Desenvolvimento com watch
npm run build             # Build de produção
npm run test              # Testes unitários
npm run test:e2e          # Testes end-to-end
npm run test:cov          # Cobertura de testes
npm run lint              # Lint com auto-fix
npm run format            # Formatação Prettier

# CLI NestJS
nest generate resource <nome>     # Módulo completo (module + controller + service)
nest generate module <nome>
nest generate controller <nome>
nest generate service <nome>
```

---

## Checklist — Nova Feature

- [ ] `src/<domain>/<domain>.module.ts`
- [ ] `src/<domain>/<domain>.controller.ts` (com `GET /test` smoke test)
- [ ] `src/<domain>/<domain>.service.ts`
- [ ] `src/<domain>/dto/create-<domain>.dto.ts`
- [ ] `src/<domain>/models/<domain>.types.ts`
- [ ] `src/<domain>/<domain>.service.spec.ts`
- [ ] `src/<domain>/<domain>.controller.spec.ts`
- [ ] `test/<domain>.e2e-spec.ts`
- [ ] Módulo registrado no `AppModule`

---

## Checklist — Correção de Bug

1. Escrever teste que reproduz o bug (deve falhar)
2. Corrigir o código
3. Confirmar que o teste passa
4. Rodar `npm run test` para garantir que nada quebrou
